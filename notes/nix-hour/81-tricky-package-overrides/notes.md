# Tricky Package Overrides

Official nix formatter can be found at:

- [nixfmt](https://github.com/NixOS/nixfmt)

How to get complete sha256 of a build:

- go to the github page for the repository
- click on the time icon at the top of the table
- Clock on the copy link for the specific commit you are interested in

Getting a url to a specific checking:

- <https://github.com/{username}/{projectname}/archive/{sha}.zip>

Getting apermanent linkt to a file:

For example to get a link to the specific version of the file:
<https://github.com/github/codeql/blob/main/README.md>

You need to get the sha256 for the version:

<https://github.com/github/codeql/blob/b212af08a6cffbb434f3c8a2795a579e092792fd/README.md>

Getting help on command line for configuring nix packages:

```
man configuration.nix
```

Mechanisms to get nixpkgs in deterministic fashion:

- niv
- npins
- flakes

An alternative mechanism is provided below

## Download nixpkgs

# content for: ./00-step-determine-sha256.nix

```nix
{ system ? builtins.currentSystem }:
let
  nixpkgs = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/";
    sha256 = "";
  };
  pkgs = import nixpkgs {
    config = { };
    overlays = [ ];
    inherit system;
  };
in pkgs.hello
```

The sha256 is set to blank to get the correct value after the
download. An empty string is assumed to be an all 'A' hash.

Will build the derivation and get an error with the correct hash:

```
nix-build ./00-step-determine-sha256.nix
```

The error message provides us with the correct hash:

```
       error: hash mismatch in file downloaded from 'https://github.com/NixOS/nixpkgs/archive/f958e5369ed761df557c362d4de3566084e9eefb.tar.gz':
         specified: sha256:0000000000000000000000000000000000000000000000000000
         got:       sha256:00ba9h4hlhs0hszx5lmh0wi07j3vriafv6llhwc6vb99wy81rn14

```

The command nix-build runs two steps:

- nix-instantiate : translates the high level nix expression to a low level store derivation
- nix-store --realise : used to build the store derivation

Note the command "nix-build" is distinct from "nix build". The nix-build command builds the derivations
described by the Nix expressions in the specified paths. A symlink called results is placed in the current directory.
If no paths are specifed nix-build will use the default.nix in the current directory if it exists.

If a path element starts with http:// or https://, it is interpreted as a tarball. Nix-build will download
and unpack the tarball. This tarball must contain a single top-level file named default.nix.

NOTE: the build automatically gets registered as the root of the nix garbage collector. The root
will disappear once the symlink is deleted OR renamed.

## Exploring nix expressions

To return an expression without actually building and realizing it in the store:

```
nix-instantiate --eval ./01-step-simple-derivation.nix
```

NOTE: nix-build expects a derivation but will evaluate a lambda that has all arguments supplied to it.

The nix repl provides a more convenient method to explore nix expressions

```bash
    nix repl
    nix-repl> f = import ./01-step-simple-derivation.nix
    nix-repl> f   #  «lambda @ /home/.../81-tricky-package-overrides/01-step-simple-derivation.nix:1:1»

    # to return the derivation
    nix-repl> f {} # «derivation /nix/store/fqs92lzychkm6p37j7fnj4d65nq9fzla-hello-2.12.1.drv»

    # to print the attributes  of a derivation inside repl (change the type=derivation )
    nix-repl> f {} // { type = "";}
    # { ...
    #   «derivation /nix/store/fqs92lzychkm6p37j7fnj4d65nq9fzla-hello-2.12.1.drv»;
    #       ...
    #   pname = "hello";
    #       ...
    #   system = "x86_64-linux";
    #   version = "2.12.1"; }
```

Some important attributes for derivations:

- name
- outPath : final output for build
- system

Question: how to get pretty printing for derivations inside repl? Nix Hour displays derivations in pretty printed
format.

## packageOverrides

The use of packageOverrides is outdated, although it is used extensively in the documentation.

## building virtualbox

Initial trial build without any overrides:

```
    nix-build ./02-step-virtualbox.nix
    # /nix/store/lh61ngswknprfpzphd5sf46xxzpx2n2j-virtualbox-7.0.18
```

In the "03-step-virtualbox-package-override.nix" we attempt to build virtual
box with a dummy packageOverrides. This is done to get the path to the
derivation.

```bash
    nix-instantiate  ./03-step-virtualbox-package-override.nix
    #  /nix/store/n1jjf2h02z2h286j3lkcn83kih2ad60r-virtualbox-7.0.18.drv
```

In step 3 the we expect to get a different hash if use package overrides.

```bash
  nix-instantiate 04-step-virtualbox-package-override-no-change.nix

  # /nix/store/n1jjf2h02z2h286j3lkcn83kih2ad60r-virtualbox-7.0.18.drv

```

This results in the same hash as above. This indicates that the packageOverdide
had no impact on the derivation:

```nix
   packageOverrides = pkgs: {
     virtualboxGuestAdditions = pkgs.virtualboxGuestAdditions.overrideAttrs
       (old: { name = "${old.name}-modified"; });
   };
```

Building the step-03 or step-04 virtual-box derivations will result in the identical output.

## query nix-store

To query information about the nix store you can use the nix-store --query command.

```bash
    man nix-store-query
```

To get output paths for derivation

```bash
   nix-store -q --outputs /nix/store/n1jjf2h02z2h286j3lkcn83kih2ad60r-virtualbox-7.0.18.drv

   # /nix/store/fxajxais35qmlr6mp19x2yyhv5k9h08q-virtualbox-7.0.18-modsrc
   # /nix/store/lh61ngswknprfpzphd5sf46xxzpx2n2j-virtualbox-7.0.18

```

To get various bindings for a derivation:

```bash
    nix-store -q --binding out /nix/store/n1jjf2h02z2h286j3lkcn83kih2ad60r-virtualbox-7.0.18.drv
    /nix/store/lh61ngswknprfpzphd5sf46xxzpx2n2j-virtualbox-7.0.18
```

To the all outputs for a derivation

```bash
    nix-store -q --binding outputs /nix/store/n1jjf2h02z2h286j3lkcn83kih2ad60r-virtualbox-7.0.18.drv
        # out modsrc
        # default output is the first output above
```

## Exploring nixpkgs attributes

The 03 and 04 instantiations resulted in identical derivations. The reason
for this is that virtualboxGuestAdditions attribute does not impact the build.
We will now explore the nixpkgs attributes via the: "nix-instantiate -A" command.

We first create the file ./05-step-explore-instantiate.nix that returns pkgs. Then
we will use the "-A" option on nixpkgs to see what attributes exist

```bash
    nix-instantiate -A virtualbox ./05-step-explore-instantiate.nix
    # /nix/store/n1jjf2h02z2h286j3lkcn83kih2ad60r-virtualbox-7.0.18.drv
```

Next we try to access virtualboxGuestAdditions:

```bash
    nix-instantiate -A virtualboxGuestAdditions ./05-step-explore-instantiate.nix
    # error: attribute 'virtualboxGuestAdditions' in selection path 'virtualboxGuestAdditions' not found
```

## Determining derivation attributes

You can find where nixpkgs resolves to in your system by running:

```bash
    nix-instantiate --find-file nixpkgs
    # /home/.../nix-defexpr/channels/nixpkgs
    #   can inspect contents of directory to see nixpkgs
```

It is best to avoid using channels for nix. A mechanism to avoid using channels
and get a sane stable stateless nixos:
[Sanix](https://github.com/infinisil/sanix/tree/main)

The location should be in /etc/nixpkgs if you are not using channels. It is
recommended not to use channels. The location of nixpkgs on your machine
contains a version of nixpkgs that can be explored. It is not a git repository
however.

First we should look at the source code.

We should clone nixpkgs.

```bash
    git clone https://github.com/NixOS/nixpkgs.git
```

Switch to the correct checking of the repository:

```bash
    git switch f958e5369ed761df557c362d4de3566084e9eefb --detach
    # HEAD is now at f958e5369ed7 Merge pull request #329040 from pbsds/fix-monty-1721611245
```

You can checkout all updates from upstream using the command:

```bash
    git fetch upstream
```

### Mechanisms to find derivations

Inside your nixpkgs directory run the following commands:

```bash
    nix repl -f .
    # can use tab completion
    nix-repl> virtualbox
    # /nix/store/n1jjf2h02z2h286j3lkcn83kih2ad60r-virtualbox-7.0.18.drv»
    nix-repl> virtualbox.meta.position
    # "/home/.../applications/virtualization/virtualbox/default.nix:275"
```

The location of attributes can be found using the builtins.unsafeGetAttrPos command

```bash
    nix repl -f .

    nix-repl> builtins.unsafeGetAttrPos "description" virtualbox.meta
        # { column = 5;
        #   file = "/home/.../virtualization/virtualbox/default.nix";
        #   line = 275; }

```

The builtins.unsafeGetattrPos is impure because it depends on the state of an
external file. If the external file changes, the output has the potential to
change. It is fine to use this function for debugging purposes. It is
non-referentially transparent.

An alternative mechanism to open the location of an attribute is given below:

```bash
    nix edit -f . virtualbox
```

We can see that the virtualboxGuestAdditionsIso attribute exists. At the top of
the file are a set of arguments that are provided to the derivation. A lot of
the arguments are provided through nixpkgs. The arguments with defaults are
generally not provided by nixpkgs.

The override command is useful when overriding the top-level arguments:

```bash
    nix repl -f .

    nix-repl> pkgs.virtualbox.override {javaBindings = false; }
    # «derivation /nix/store/fbvsmcjfqzah83xk6d6q8glrh0ifcdbm-virtualbox-7.0.18.drv»
```

The hash above is different than before.

## VirtualBoxGuestAdditionsIso

The callPackage fills in the arguments for virtualBoxGuestAdditionsIso.

```nix
      virtualboxGuestAdditionsIso = callPackage guest-additions-iso/default.nix { };
```

The above file is a simple declaration:

```nix
    { fetchurl, lib, virtualbox}:

    let
      inherit (virtualbox) version;
    in
    fetchurl {
      url = "http://download.virtualbox.org/virtualbox/${version}/VBoxGuestAdditions_${version}.iso";
      sha256 = "4469bab0f59c62312b0a1b67dcf9c07a8a971afad339fa2c3eb80e209e099ef9";
      meta = {
        description = "Guest additions ISO for VirtualBox";
        longDescription = ''
          ISO containing various add-ons which improves guests inside VirtualBox.
        '';
        sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
        license = lib.licenses.gpl2;
        maintainers = [ lib.maintainers.sander lib.maintainers.friedrichaltheide ];
        platforms = [ "i686-linux" "x86_64-linux" ];
      };
    }
```

Question is how to change the VirtualBoxGuestAdditionsIso. This statement is in the "let/in" statement.
Generally these statements are not good for overriding.

### Method One Changing virtualboxGuestAdditionsIso

The virtualboxGuestAdditionsIso is an attribute to mkDerivation.

```nix
  ...
  in stdenv.mkDerivation (finalAttrs: {
    pname = "virtualbox";
    version = finalAttrs.virtualboxVersion;

    inherit buildType virtualboxVersion virtualboxSha256 kvmPatchVersion kvmPatchHash virtualboxGuestAdditionsIso;

    src = fetchurl {
    ...

```

The ".override" overrides the arguments at the top level. And overrideAttrs,
which overrides the attributes of a derivation. The addition to the nix file is
given below

```nix
      packageOverrides = pkgs: {
        virtualbox = pkgs.virtualbox.overrideAttrs (old: {
          virtualboxGuestAdditionsIso =
            old.virtualboxGuestAdditionsIso.overrideAttrs
            (old': { name = "${old'.name}-modified"; });
        });
      };
    };

```

```bash
    nix-instantiate -A virtualbox 06-step-explore-override-attrs-package-override.nix
    # /nix/store/qawx1d0w4mr97sv7z0912d0b2lh7xjcb-virtualbox-7.0.18.drv
```

The above hash is different than before. Without the update the hash was:

```bash
    /nix/store/n1jjf2h02z2h286j3lkcn83kih2ad60r-virtualbox-7.0.18.drv
```

A useful utility to compare derivations is nix-diff. This utility can be installed via nix-shell.

```bash
    nix-diff \
        /nix/store/n1jjf2h02z2h286j3lkcn83kih2ad60r-virtualbox-7.0.18.drv \
        /nix/store/qawx1d0w4mr97sv7z0912d0b2lh7xjcb-virtualbox-7.0.18.drv \
            # • The set of input derivation names do not match:
            #     - VBoxGuestAdditions_7.0.18.iso
            #     + VBoxGuestAdditions_7.0.18.iso-modified``
```

The updated virtualbox can be built using the command:

```bash
    nix-build -A virtualbox    
```

The above command seems to take a long time. The approximate build times can be
checked against the hydra website: [hydra](http://hydra.nixos.org). We can click on
nixpkgs. There are many different branches for various builds. It is usually safe to 
check the trunk branch by default.

On the trunk page select the "Jobs" tab and search for virtualbox in the top search bar.
once the results return scroll through and find virtualbox. Click on a succeeding build.
It takes approximately 9 minutes for the build.
