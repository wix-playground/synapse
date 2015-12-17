require 'spec_helper'
require 'fileutils'

describe Synapse::NginxConfig do
  subject { Synapse::NginxConfig.new(config['file_output']) }

  before(:example) do
    FileUtils.mkdir_p(config['file_output']['output_directory'])
  end

  after(:example) do
    FileUtils.rm_r(config['file_output']['output_directory'])
  end

  let(:mockwatcher_1) do
    mockWatcher = double(Synapse::ServiceWatcher)
    allow(mockWatcher).to receive(:name).and_return('example_service')
    backends = [{ 'host' => 'somehost', 'port' => 5555}]
    allow(mockWatcher).to receive(:backends).and_return(backends)
    mockWatcher
  end
  let(:mockwatcher_2) do
    mockWatcher = double(Synapse::ServiceWatcher)
    allow(mockWatcher).to receive(:name).and_return('foobar_service')
    backends = [{ 'host' => 'somehost', 'port' => 1234}]
    allow(mockWatcher).to receive(:backends).and_return(backends)
    mockWatcher
  end

  it 'updates the config' do
    expect(subject).to receive(:write_backends_to_file)
    subject.update_config([mockwatcher_1])
  end

  it 'manages correct files' do
    subject.update_config([mockwatcher_1, mockwatcher_2])
    FileUtils.cd(config['file_output']['output_directory']) do
      expect(Dir.glob('*.conf')).to eql(['example_service.conf', 'foobar_service.conf'])
    end
    # Should clean up after itself
    subject.update_config([mockwatcher_1])
    FileUtils.cd(config['file_output']['output_directory']) do
      expect(Dir.glob('*.conf')).to eql(['example_service.conf'])
    end
    # Should clean up after itself
    subject.update_config([])
    FileUtils.cd(config['file_output']['output_directory']) do
      expect(Dir.glob('*.conf')).to eql([])
    end
  end

  it 'writes correct content' do
    subject.update_config([mockwatcher_1])
    data_path = File.join(config['file_output']['output_directory'],
                          "example_service.conf")
     backends = File.read(data_path)
     expect(backends).to match("upstream example_service")
     expect(backends).to match("somehost:5555")
  end
end
