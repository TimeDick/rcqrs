require File.join(File.dirname(__FILE__), '../spec_helper')

module EventStore
  describe DomainRepository do
    before(:each) do
      @storage = Adapters::InMemoryAdapter.new
      @repository = DomainRepository.new(@storage)
      @aggregate = Domain::Company.create('ACME Corp.')
    end

    context "when saving an aggregate" do
      before(:each) do
        @repository.save(@aggregate)
      end

      it "should persist the aggregate's applied events" do
        @storage.storage.has_key?(@aggregate.guid)
      end
    end
    
    context "when finding an aggregate that does not exist" do
      it "should raise an EventStore::AggregateNotFound exception" do
        proc { @repository.find('missing') }.should raise_error(EventStore::AggregateNotFound)
      end
    end
    
    context "when loading an aggregate" do
      before(:each) do
        @storage.save(@aggregate)
        @retrieved = @repository.find(@aggregate.guid)
      end
      
      subject { @retrieved }
      it { should be_instance_of(Domain::Company) }
      specify { @retrieved.version.should == 1 }
      specify { @retrieved.applied_events.length.should == 1 }
    end
    
    context "when reloading same aggregate" do
      before(:each) do
        @storage.save(@aggregate)
        @mock_storage = mock
        @repository = DomainRepository.new(@mock_storage)
        @mock_storage.should_receive(:find).with(@aggregate.guid).once.and_return { @storage.find(@aggregate.guid) }
      end
      
      it "should only retrieve aggregate once" do
        @repository.find(@aggregate.guid)
        @repository.find(@aggregate.guid)
      end
    end
  end
end