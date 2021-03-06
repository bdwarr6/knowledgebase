.. _vm-deployment:

Deploy VMs From Controller
==========================

On Controller VM
----------------

- Create a group for the VMs (this example will create a group for infrastructure VMs within the additional groups of ``services,cluster,domain`` and containing the nodes ``infra[1-3]``)::

    metal configure group infra

- Create a deployment file for the ``infra`` group at ``/var/lib/metalware/repo/config/infra.yaml`` with the following content::

    vm:
      server: master1 master2
      virtpool: /opt/vm/
      nodename: "<%= node.name %>-<%= domain.config.cluster %>"
      primac: 52:54:00:78:<%= '%02x' % node.group.index.to_s %>:<%= '%02x' % node.index.to_s %>
      extmac: 52:54:00:78:<%= '%02x' % (node.group.index + 1).to_s %>:<%= '%02x' % node.index.to_s %>
      vncpassword: 'password'
      disksize: 250
    kernelappendoptions: "console=tty0 console=ttyS0 115200n8"
    disksetup: |
      zerombr
      bootloader --location=mbr --driveorder=vda --append="console=tty0 console=ttyS0,115200n8"
      clearpart --all --initlabel

      #Disk partitioning information
      part /boot --fstype ext4 --size=4096 --asprimary --ondisk vda
      part pv.01 --size=1 --grow --asprimary --ondisk vda
      volgroup system pv.01
      logvol  /  --fstype ext4 --vgname=system  --size=16384 --name=root
      logvol  /var --fstype ext4 --vgname=system --size=16384 --name=var
      logvol  /tmp --fstype ext4 --vgname=system --size=1 --grow --name=tmp
      logvol  swap  --fstype swap --vgname=system  --size=8096  --name=swap1

.. note:: Replace ``master1 master2`` with the hostnames of the libvirt master, ensure that there's an entry for the server in ``/etc/hosts``. If there are more than one VM servers then create a space separated list

- Add the following to the configuration file for the controller node at ``/var/lib/metalware/repo/config/self.yaml`` (using the same vm server names as above)::

    vm:
      server: master1 master2

- Install the libvirt client package on the controller for managing the VM master server::

    yum -y install libvirt-client virt-install

- Additionally, download the certificate authority script to ``/opt/alces/install/scripts/certificate_authority.sh`` and VM creation script to ``/opt/alces/install/scripts/vm.sh``::

    mkdir -p /opt/alces/install/scripts/
    cd /opt/alces/install/scripts/
    wget https://raw.githubusercontent.com/alces-software/knowledgebase/master/epel/7/certificate_authority/certificate_authority.sh
    wget https://raw.githubusercontent.com/alces-software/knowledgebase/master/epel/7/libvirt/vm.sh

- Add the master server IP to ``/etc/hosts`` on the controller

- Run the script to configure the certificate authority (and perform any additional steps which the script instructs)::

    metal render /opt/alces/install/scripts/certificate_authority.sh self |/bin/bash

On Master VM
------------

- Uncomment the line ``LIBVIRTD_ARGS="--listen"`` in ``/etc/sysconfig/libvirtd``

- Restart libvirtd service::

    systemctl restart libvirtd

Back on Controller VM
---------------------

- Add the following line to ``/etc/libvirt/libvirt.conf`` to automatically query the VM master::

    uri_default = "qemu://master1/system"

.. note:: If using multiple VM masters then a different master can be specified using ``-c qemu://master2/system`` as an argument to ``virsh`` or ``virt-install``

- Run the script for a node::

    metal render /opt/alces/install/scripts/vm.sh infra1 |/bin/bash

- Alternatively, run the script for the entire group::

    metal each -g infra 'metal render /opt/alces/install/scripts/vm.sh <%= node.name %> |/bin/bash'

- The above will create the virtual machines, these will then need to be started (from the VM master with ``virsh start infra1-testcluster``) and the metal build command run to grab them for the build::

    metal build infra1

