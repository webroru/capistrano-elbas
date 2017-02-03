require 'elbas'

namespace :elbas do
  task :scale do
    set :aws_access_key_id,     fetch(:aws_access_key_id,     ENV['AWS_ACCESS_KEY_ID'])
    set :aws_secret_access_key, fetch(:aws_secret_access_key, ENV['AWS_SECRET_ACCESS_KEY'])

    Elbas::AMI.create do |ami|
      p "ELBAS: Created AMI: #{ami.aws_counterpart.id}"
      Elbas::LaunchConfiguration.create(ami) do |lc|
        p "ELBAS: Created Launch Configuration: #{lc.aws_counterpart.name}"
        lc.attach_to_autoscale_group!
      end
    end
  end

  task :decrease_instances do
    p 'Start Decreasing instances'
    p "Current Desired capacity is: #{autoscale_group.desired_capacity}"
    p "Current Min size is: #{autoscale_group.min_size}"
    p "New Min size is: #{fetch(:aws_autoscaling_min_size)}"

    autoscale_group.update({
      min_size: fetch(:aws_autoscaling_min_size),
    })
    p 'Numbers of instances set to original successfully!'
  end

end
