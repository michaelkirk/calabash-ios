class CoreIncluded
  include Calabash::Cucumber::Core
end

describe Calabash::Cucumber::Core do

  before(:each) {
    ENV.delete('DEVELOPER_DIR')
    ENV.delete('DEBUG')
    ENV.delete('DEVICE_ENDPOINT')
    ENV.delete('DEVICE_TARGET')
    RunLoop::SimControl.terminate_all_sims
  }

  after(:each) {
    ENV.delete('DEVELOPER_DIR')
    ENV.delete('DEBUG')
    ENV.delete('DEVICE_ENDPOINT')
    ENV.delete('DEVICE_TARGET')
  }

  describe '#calabash_exit' do
    describe 'targeting simulators' do
      let(:launcher) { Calabash::Cucumber::Launcher.new }
      let(:core_instance) { CoreIncluded.new }
      it "Xcode #{Resources.shared.current_xcode_version}" do
        device_target = 'simulator'
        if Resources.shared.travis_ci?
          if Resources.shared.current_xcode_version >= RunLoop::Version.new('6.0')
            device_target = 'iPad Air (8.0 Simulator)'
          end
        end
        sim_control = RunLoop::SimControl.new
        options =
              {
                    :app => Resources.shared.app_bundle_path(:lp_simple_example),
                    :device_target =>  device_target,
                    :sim_control => sim_control,
                    :launch_retries => Resources.shared.travis_ci? ? 5 : 2
              }
        launcher.relaunch(options)
        expect(launcher.run_loop).not_to be == nil
        expect { core_instance.calabash_exit }.not_to raise_error
      end

      describe 'Xcode regression' do
        xcode_installs = Resources.shared.alt_xcodes_gte_xc51_hash
        if xcode_installs.empty?
          it 'no alternative Xcode installs' do
            expect(true).to be == true
          end
        else
          xcode_installs.each do |install_hash|
            version = install_hash[:version]
            path = install_hash[:path]
            it "Xcode #{version} @ #{path}" do
              ENV['DEVELOPER_DIR'] = path
              sim_control = RunLoop::SimControl.new
              options =
                    {
                          :app => Resources.shared.app_bundle_path(:lp_simple_example),
                          :device_target => 'simulator',
                          :sim_control => sim_control,
                          :launch_retries => Resources.shared.travis_ci? ? 5 : 2
                    }
              launcher.relaunch(options)
              expect(launcher.run_loop).not_to be == nil
              expect { core_instance.calabash_exit }.not_to raise_error
            end
          end
        end
      end
    end

    unless Resources.shared.travis_ci?
      describe 'targeting physical devices' do
        describe "Xcode #{Resources.shared.current_xcode_version}" do

          let(:launcher) { Calabash::Cucumber::Launcher.new }
          let(:core_instance) { CoreIncluded.new }

          xctools = RunLoop::XCTools.new
          physical_devices = xctools.instruments :devices

          if physical_devices.empty?
            it 'no devices attached to this computer' do
              expect(true).to be == true
            end
          elsif not Resources.shared.ideviceinstaller_available?
            it 'device testing requires ideviceinstaller to be available in the PATH' do
              expect(true).to be == true
            end
          else
            physical_devices.each do |device|
              if device.version >= RunLoop::Version.new('8.0') and xctools.xcode_version < RunLoop::Version.new('6.0')
                it "Skipping #{device.name} iOS #{device.version} with Xcode #{version} - combination not supported" do
                  expect(true).to be == true
                end
              else
                it "on #{device.name} iOS #{device.version} Xcode #{xctools.xcode_version}" do
                  ENV['DEVICE_ENDPOINT'] = "http://#{device.name}.local:37265"
                  options =
                        {
                              :bundle_id => Resources.shared.bundle_id,
                              :udid => device.udid,
                              :device_target => device.udid,
                              :sim_control => RunLoop::SimControl.new,
                              :launch_retries => Resources.shared.travis_ci? ? 5 : 2
                        }
                  expect { Resources.shared.ideviceinstaller(device.udid, :install) }.to_not raise_error

                  launcher.relaunch(options)
                  expect(launcher.run_loop).not_to be == nil
                  expect { core_instance.calabash_exit }.not_to raise_error
                end
              end
            end
          end
        end
      end

      describe 'Xcode regression' do
        let(:launcher) { Calabash::Cucumber::Launcher.new }
        let(:core_instance) { CoreIncluded.new }

        xcode_installs = Resources.shared.alt_xcodes_gte_xc51_hash
        physical_devices = RunLoop::XCTools.new.instruments :devices
        if not xcode_installs.empty? and Resources.shared.ideviceinstaller_available? and not physical_devices.empty?
          xcode_installs.each do |install_hash|
            version = install_hash[:version]
            path = install_hash[:path]
            physical_devices.each do |device|
              if device.version >= RunLoop::Version.new('8.0') and version < RunLoop::Version.new('6.0')
                it "Skipping #{device.name} iOS #{device.version} with Xcode #{version} - combination not supported" do
                  expect(true).to be == true
                end
              else
                it "Xcode #{version} @ #{path} #{device.name} iOS #{device.version}" do
                  ENV['DEVELOPER_DIR'] = path
                  ENV['DEVICE_ENDPOINT'] = "http://#{device.name}.local:37265"
                  options =
                        {
                              :bundle_id => Resources.shared.bundle_id,
                              :udid => device.udid,
                              :device_target => device.udid,
                              :sim_control => RunLoop::SimControl.new,
                              :launch_retries => Resources.shared.travis_ci? ? 5 : 2
                        }
                  expect { Resources.shared.ideviceinstaller(device.udid, :install) }.to_not raise_error

                  launcher.relaunch(options)
                  expect(launcher.run_loop).not_to be == nil
                  expect { core_instance.calabash_exit }.not_to raise_error
                end
              end
            end
          end
        end
      end
    end
  end
end
