# vm-bhyve-qemu

>IN DEVELOPMENT STAGE. IN PROGRESS

Management system for QEMU/KVM virtual machines on Linux.

This project is a Linux/QEMU fork of [vm-bhyve](https://github.com/freebsd/vm-bhyve).  
The goal is to keep the simple `vm-bhyve` command-line interface and configuration
file format, while using `qemu-system-*` with KVM instead of FreeBSD's `bhyve`
hypervisor.

In other words, this is intended to be a convenient management interface around
QEMU/KVM, rather than a replacement for QEMU or a new hypervisor.

Most of the original `vm-bhyve` workflow is intentionally kept intact. Existing
configuration concepts such as guests, templates, datastores, virtual switches,
disks and network interfaces are translated into the corresponding QEMU/Linux
configuration.

Some of the main features include:

* Windows/UEFI support
* Simple commands to create/start/stop QEMU/KVM instances
* Simple configuration file format
* Linux bridge-based virtual switches with VLAN support
* ZFS support when available
* FreeBSD/Linux/Windows and other QEMU-supported guest operating systems
* Console access through QEMU's serial console
* Integration with systemd startup/shutdown
* Guest reboot handling
* Designed with multiple compute nodes + shared storage in mind (NFS/iSCSI/etc)
* Multiple datastores
* VNC graphics & tmux support
* Dependency free at the management-script level

### Optional dependencies

Some additional packages may be required in certain circumstances:

* `qemu-system-x86` provides the x86 QEMU system emulator
* `qemu-utils` provides tools such as `qemu-img`
* `ovmf` provides UEFI firmware for x86 guests
* `tmux` is needed to use tmux console access
* `iproute2` provides Linux networking utilities used for virtual switches,
  bridges, VLANs and TAP devices
* `zfsutils-linux` is required if ZFS is used for VM storage
* `cloud-init` is used inside cloud guests when using cloud-init images

Package names vary between Linux distributions.

### See the GitHub wiki for more information and examples

The project is based on the original `vm-bhyve` workflow, but its Linux/QEMU
backend is developed independently.

## Quick-Start

A simple overview of the commands needed to install vm-bhyve-qemu and start a
Linux guest.

    1. Install QEMU/KVM and the required Linux packages
    2. Create a directory for your virtual machines
    3. Set vm_dir in the vm-bhyve-qemu configuration
    4. Run `vm init`
    5. Install the sample templates
    6. Create a Linux bridge for guest networking
    7. Attach the bridge to the desired host network interface
    8. Download a Linux ISO
    9. Create a guest
    10. Install the guest
    11. Connect to the guest console

For example, on Debian/Ubuntu:

    # apt install qemu-system-x86 qemu-utils ovmf iproute2 tmux

Create a directory for your virtual machines:

    # mkdir -p /var/lib/vm-bhyve

Set the datastore directory in the vm-bhyve-qemu configuration:

    vm_dir="/var/lib/vm-bhyve"

Initialize the datastore:

    # vm init

Install the sample templates:

    # cp ./sample-templates/* /var/lib/vm-bhyve/.templates/

Create a Linux bridge called `public` and attach the appropriate physical
interface to it using your distribution's networking tools.

    # vm switch create public
    # vm switch add public enp1s0

Download an ISO:

    # vm iso https://example.org/linux.iso

Create and install a guest:

    # vm create myguest
    # vm install myguest linux.iso
    # vm console myguest

At this point proceed through the installation as normal.

## Install

Clone or download the latest release from GitHub.

To install, run the following command inside the vm-bhyve-qemu source directory:

    # make install

You will also need QEMU/KVM:

    # apt install qemu-system-x86 qemu-utils

For UEFI guests, install OVMF:

    # apt install ovmf

The exact package names depend on the Linux distribution.

## Initial configuration

First of all, you will need a directory to store all your virtual machines and
vm-bhyve-qemu configuration.

If you are not using ZFS, create a normal directory:

    # mkdir -p /var/lib/vm-bhyve

If you are using ZFS, create a dataset to hold vm-bhyve-qemu data:

    # zfs create pool/vm

Now configure vm-bhyve-qemu and tell it where your directory is:

    vm_dir="/var/lib/vm-bhyve"

Or with ZFS:

    vm_dir="zfs:pool/vm"

This directory will be referred to as `$vm_dir` in the rest of this README.

Now run the following command to create the directories used to store
vm-bhyve-qemu configuration and state and to perform any required initialization:

    # vm init

On Linux, host startup is handled by systemd rather than FreeBSD's rc.d
framework. If you want guests to start automatically, enable the corresponding
vm-bhyve-qemu systemd service or use the project's startup integration.

## Virtual machine templates

When creating a virtual machine, you use a template which defines how much
memory to give the guest, how many CPU cores, and networking/disk configuration.
The templates are stored inside `$vm_dir/.templates`.

To install the sample templates:

    # cp ./sample-templates/* /var/lib/vm-bhyve/.templates/

Template files retain the simple `vm-bhyve` configuration syntax. QEMU-specific
values are generated by the Linux backend.

For example:

    guest="linux"
    cpu=1
    memory=512M
    disk0_type="virtio-blk"
    disk0_name="disk0.img"
    network0_type="virtio-net"
    network0_switch="public"

The template describes the desired virtual hardware rather than a raw QEMU
command line. The backend translates these settings into QEMU arguments.

You will notice that each template is set to create one network interface.
You can easily add more network interfaces by duplicating the two network
configuration options and incrementing the number.

In general you will want to use `virtio-net` for network interfaces and
`virtio-blk` for disks when the guest supports them.

I recommend reading the man page or `sample-templates/config.sample` for a full
list of supported template options and a description of their purpose.

Not every bhyve-specific option has a direct QEMU equivalent. Options that are
specific to bhyve hardware or boot loaders are translated, replaced or ignored
by the QEMU backend where appropriate.

## Virtual Switches

When a guest is started, each network interface is automatically connected to
the virtual switch specified in the configuration file.

On Linux, a virtual switch is implemented using a Linux bridge and TAP
interfaces. The bridge can either be an isolated guest network or be connected
to a physical host interface.

By default the sample templates connect to a switch called `public`:

    # vm switch create public

To bridge guests to your physical network, add the appropriate real interface
to the switch. Replace `enp1s0` with the correct interface on your system:

    # vm switch add public enp1s0

The underlying Linux networking is managed using standard Linux networking
facilities such as `ip`, bridge devices and TAP interfaces.

If you want guest traffic to use a specific VLAN when leaving the host,
configure the VLAN on the Linux bridge/host networking layer. VLAN handling is
therefore implemented using Linux networking rather than FreeBSD's native
networking stack.

You can view the current switch configuration using:

    # vm switch list

## Creating virtual machines

Use one of the following commands to create a new virtual machine:

    # vm create testvm
    # vm create -t templatename -s 50G testvm

The first example uses the `default.conf` template and will create a 20GB disk
image. The second example specifies the `templatename.conf` template and tells
vm-bhyve-qemu to create a 50GB disk.

QEMU disk images can be RAW or QCOW2. The default image format depends on the
configuration.

You will need an ISO to install the guest with, so download one using the
`iso` command:

    # vm iso https://example.org/linux.iso

To start a guest installation, run:

    # vm install testvm linux.iso
    # vm console testvm

The guest runs in the background, so use the `console` command to connect to
its serial console.

You can also specify the foreground option to run the guest directly on your
terminal:

    # vm install -f testvm linux.iso

Once installation has finished, reboot the guest from inside the console and it
will boot into the newly installed OS.

The following commands start and stop virtual machines:

    # vm start testvm
    # vm stop testvm

The basic configuration and state of each machine can be viewed using:

    # vm list

    NAME            GUEST      LOADER    CPU    MEMORY    AUTOSTART    STATE
    alpine          linux      default   1      512M      No           Stopped
    debian          linux      default   2      2G        No           Stopped
    ubuntu          linux      default   2      2G        Yes          Running
    wintest         windows    uefi      4      4G        No           Stopped

All running machines can be stopped using:

    # vm stopall

On host boot, vm-bhyve-qemu can use the `vm startall` command to start all
machines. Automatic startup is handled by systemd on Linux.

You can control which guests start automatically using the vm-bhyve-qemu
configuration:

    vm_list="vm1 vm2"
    vm_delay="5"

The first defines the list of machines to start on boot and the order in which
they are started. The second is the number of seconds to wait between starting
each one.

There's also a command which opens a guest's configuration file in your default
text editor, allowing you to easily make changes. Changes only take effect after
a full shutdown and restart of the guest:

    # vm configure testvm

See the man page for a full description of all available commands:

    # man vm

## Using cloud images

You can use cloud images to create virtual machines. The `vm img` command
downloads the image to the datastore and uncompresses it if needed
(`.xz`, `.tar.gz`, and `.gz` files are supported).

The image should be in RAW or QCOW2 format.

QEMU's `qemu-img` utility is used for image creation and inspection.

For example, install the QEMU utilities:

    # apt install qemu-utils

To list downloaded images:

    # vm img

    DATASTORE           FILENAME
    default             debian-12-generic-amd64.qcow2
    default             ubuntu-24.04-server-cloudimg-amd64.img
    default             fedora-cloud-base.qcow2

To create a guest from a cloud image:

    # vm create -t linux -i ubuntu-24.04-server-cloudimg-amd64.img ubuntu-cloud
    # vm start ubuntu-cloud

## Using cloud-init

vm-bhyve-qemu has basic support for providing cloud-init configuration to the
guest.

You can enable it with the `-C` option to `vm create`. You can also pass a
public SSH key to be injected into the guest with `-k <file>`.

The public key file can contain multiple public SSH keys, one per line, in the
`authorized_keys` format.

`vm create` also has an option for setting network parameters:

    -n "interface=;ip=;gateway4=;gateway6=;nameservers=;searchdomains=;hostname="

Example:

    interface=eth0;ip=10.0.0.2/24;gateway4=10.0.0.1;nameservers=1.1.1.1,8.8.8.8;hostname=testvm

The exact interface name visible inside the guest depends on the guest OS and
its network configuration.

Example:

    # vm create -t linux -i ubuntu-24.04-server-cloudimg-amd64.img -C -k ~/.ssh/id_rsa.pub cloud-init-ubuntu
    # vm start cloud-init-ubuntu
    Starting cloud-init-ubuntu
    * found guest in /var/lib/vm-bhyve/cloud-init-ubuntu
    * booting...
    # ssh ubuntu@192.168.0.91

### Editing cloud-init configuration

To edit generated cloud-init configuration files, such as meta-data,
network-config and user-data, specify the configuration file for the
`vm configure` command.

Please note that cloud-init typically runs only on the first boot. Changes made
after the first boot do not take effect.

    # vm configure <name> user-data

## Adding custom disks

You can add additional virtual disks stored outside the main datastore.

For example, create a sparse 50G QCOW2 image:

    # qemu-img create -f qcow2 /somewhere/disk1.qcow2 50G

Add it to your VM configuration:

    # vm configure yourvm

    disk1_name="/somewhere/disk1.qcow2"
    disk1_type="virtio-blk"
    disk1_dev="custom"

Restart your VM.

For raw block devices, the `disk*_name` option can point to an appropriate
Linux block-device path, provided the QEMU process has permission to access it.

## Windows Support

Windows guests are supported through QEMU/KVM.

UEFI guests require OVMF firmware. Depending on the Windows version, additional
virtual hardware such as a TPM may be required.

For Windows-specific configuration examples, see the project wiki.

## Autocomplete

The original `vm-bhyve` autocomplete configuration targets FreeBSD's
`csh`/`tcsh`. On Linux, the recommended shell integration is Bash completion.

If Bash completion is provided by the project, install or source the completion
file from the project and then reload your shell:

    # source /etc/bash_completion

The completion should provide command, guest and ISO/image completion.

For Zsh users, the same command structure can be exposed through a Zsh
completion function.

## Notes on the Linux/QEMU port

This project intentionally keeps the original `vm-bhyve` user interface and
configuration style where practical, but the underlying virtualization stack is
different.

On FreeBSD:

    vm-bhyve -> bhyve -> FreeBSD kernel virtualization

On Linux:

    vm-bhyve-qemu -> qemu-system-* -> KVM -> Linux kernel

QEMU is responsible for device emulation and VM management, while KVM provides
hardware-assisted CPU virtualization.

The project does not require libvirt. QEMU/KVM can be launched directly, and
the purpose of this tool is to provide the same simple management workflow that
made `vm-bhyve` convenient on FreeBSD.
