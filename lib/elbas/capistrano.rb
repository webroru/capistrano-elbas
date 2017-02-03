require 'aws-sdk-v1'
require 'capistrano/dsl'

load File.expand_path("../tasks/elbas.rake", __FILE__)

def autoscale(groupname, *args)
  include Capistrano::DSL
  include Elbas::AWS::AutoScaling
  include Elbas::ExtraInstance

  autoscale_group = autoscaling.groups[groupname]
  set :aws_autoscale_group, groupname

  additional_instances_amount = fetch(:aws_additional_instances_amount, 0)
  if additional_instances_amount > 0
    increase(additional_instances_amount)
  end

  running_instances = autoscale_group.ec2_instances.filter('instance-state-name', 'running')

  running_instances.each do |instance|
    hostname = instance.dns_name || instance.private_ip_address
    p "ELBAS: Adding server: #{hostname}"
    server(hostname, *args)
  end

  if running_instances.count > 0
    after('deploy', 'elbas:scale')
  else
    p "ELBAS: AMI could not be created because no running instances were found. Is your autoscale group name correct?"
  end
end
