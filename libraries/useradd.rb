class Chef
  class Provider
    class User
      class Useradd < Chef::Provider::User
        if Chef::Node.load(Chef::Config['node_name']).platform?('smartos')
          UNIVERSAL_OPTIONS = [[:comment, '-c'], [:gid, '-g'], [:password, '-p'], [:shell, '-s'], [:uid, '-u']]

          # May want to change default group from 'other' to 'username' to make smartos behavior similar to linux default.
          # this would involve testing for gid and if not found creating group with username instead of defaulting to 'other'

          def create_user
            command = compile_command('useradd') do |useradd|
              useradd.concat(universal_options)
              useradd.concat(useradd_options)
            end.join(' ')
            shell_out!(command)

            # SmartOS locks new users by default until password is set
            # unlock the account by default because password is set by chef
            unlock_user if check_lock
          end

          def check_lock
            passwd_s = shell_out!('passwd', '-s', new_resource.username, returns: [0,1])
            status_line = passwd_s.stdout.split(' ')
            case status_line[1]
            when /^P/
              @locked = false
            when /^N/
              @locked = false
            when /^L/
              @locked = true
            end

            unless passwd_s.exitstatus == 0
              raise Chef::Exceptions::User, "Cannot determine if #{new_resource} is locked!"
            end

            @locked
          end

          def lock_user
            shell_out!('passwd', '-l', @new_resource.username)
          end

          def unlock_user
            shell_out!('passwd', '-u', @new_resource.username)
          end

          def universal_options
            opts = []

            UNIVERSAL_OPTIONS.each do |field, option|
              if @current_resource.send(field) != @new_resource.send(field)
                if @new_resource.send(field)
                  Chef::Log.debug("#{@new_resource} setting #{field} to #{@new_resource.send(field)}")
                  opts << " #{option} '#{@new_resource.send(field)}'"
                end
              end
            end
            if updating_home?
              if managing_home_dir?
                Chef::Log.debug("#{@new_resource} managing the users home directory")
                opts << "-m -d '#{@new_resource.home}'"
              else
                Chef::Log.debug("#{@new_resource} setting home to #{@new_resource.home}")
                opts << "-d '#{@new_resource.home}'"
              end
            end
            opts << '-o' if @new_resource.non_unique || @new_resource.supports[:non_unique]
            opts
          end

          def useradd_options
            []
          end

          def updating_home?
            # will return false if paths are equivalent
            # Pathname#cleanpath does a better job than ::File::expand_path (on both unix and windows)
            # ::File.expand_path("///tmp") == ::File.expand_path("/tmp") => false
            # ::File.expand_path("\\tmp") => "C:/tmp"
            return true if @current_resource.home.nil? && @new_resource.home
            @new_resource.home and Pathname.new(@current_resource.home).cleanpath != Pathname.new(@new_resource.home).cleanpath
          end

          def managing_home_dir?
            @new_resource.manage_home || @new_resource.supports[:manage_home]
          end
        end
      end
    end
  end
end
