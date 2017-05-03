module Elbas
  module ExtraInstance
    def increase(amount)
      set :aws_autoscaling_min_size, autoscale_group.min_size

      p 'Increase numbers of instances'
      new_desired_capacity = autoscale_group.desired_capacity + amount
      p "Current Desired capacity is: #{autoscale_group.desired_capacity}"
      p "Current Min size is: #{autoscale_group.min_size}"
      p "New Desired capacity and Min size is: #{new_desired_capacity}"

      autoscale_group.update({
        desired_capacity: new_desired_capacity,
        min_size: new_desired_capacity,
      })

      p 'Start awaiting for new instances added'
      elapsed_time = 0
      step = 10
      while autoscale_group.ec2_instances.filter('instance-state-name', 'running').count < new_desired_capacity do
        sleep step
        elapsed_time += step
        if elapsed_time % 60 == 0
          p "#{elapsed_time / 60} minutes passed..."
        end
        if elapsed_time > 60 * 10
          abort 'New instance adding time is out'
        end
      end

      p 'Check the status of the instances'
      elapsed_time = 0
      step = 10
      while autoscale_group.ec2_instances.filter('instance-status.status', 'ok').count < new_desired_capacity do
        sleep step
        elapsed_time += step
        if elapsed_time % 60 == 0
          p "#{elapsed_time / 60} minutes passed..."
        end
        if elapsed_time > 60 * 10
          abort 'New instances are not reachable'
        end
      end

      p 'Check the status of the system'
      elapsed_time = 0
      step = 10
      while autoscale_group.ec2_instances.filter('system-status.status', 'ok').count < new_desired_capacity do
        sleep step
        elapsed_time += step
        if elapsed_time % 60 == 0
          p "#{elapsed_time / 60} minutes passed..."
        end
        if elapsed_time > 60 * 10
          abort 'New instances are not reachable'
        end
      end

      p 'Instances added successful'

      after('deploy:finished', 'elbas:decrease_instances')
    end
  end
end
