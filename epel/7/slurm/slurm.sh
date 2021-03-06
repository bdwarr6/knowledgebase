SLURMCONF=`cat << EOF
ClusterName=<%= config.domain %>
ControlMachine=<%= config.slurm.server %>
SlurmUser=nobody
SlurmctldPort=6817
SlurmdPort=6818
AuthType=auth/munge
StateSaveLocation=/tmp
SlurmdSpoolDir=/tmp/slurmd
SwitchType=switch/none
MpiDefault=none
SlurmctldPidFile=/var/run/slurmctld.pid
SlurmdPidFile=/var/run/slurmd.pid
ProctrackType=proctrack/pgid
ReturnToService=2
SlurmctldTimeout=300
SlurmdTimeout=300
InactiveLimit=0
MinJobAge=300
KillWait=30
Waittime=0
SchedulerType=sched/backfill
SelectType=select/linear
FastSchedule=1
SlurmctldDebug=3
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdDebug=3
SlurmdLogFile=/var/log/slurm/slurmd.log
JobCompType=jobcomp/none
NodeName=<% genders.domain.each do |node| %><%= node %>,<% end %> State=UNKNOWN
PartitionName=all Nodes=ALL Default=YES MaxTime=UNLIMITED
EOF
`

yum -y -e0 install munge munge-devel munge-libs perl-Switch
<% if (config.slurm.is_server rescue false) -%>
yum -y -e0 install mariadb mariadb-test mariadb-libs mariadb-embedded mariadb-embedded-devel mariadb-devel mariadb-bench
systemctl enable mariadb
systemctl start mariadb
<% end -%>

echo '<%= config.slurm.mungekey %>' > /etc/munge/munge.key
chmod 400 /etc/munge/munge.key
chown munge /etc/munge/munge.key

systemctl enable munge
systemctl start munge

yum -y -e 0 --nogpgcheck install slurm slurm-devel slurm-munge slurm-perlapi slurm-plugins slurm-sjobexit slurm-sjstat slurm-torque

mkdir /var/log/slurm
chown nobody /var/log/slurm

echo "$SLURMCONF" > /etc/slurm/slurm.conf

<% if (config.slurm.is_server rescue false) -%>
systemctl enable slurmctld
systemctl start slurmctld
<% end -%>

systemctl enable slurmd
systemctl start slurmd
