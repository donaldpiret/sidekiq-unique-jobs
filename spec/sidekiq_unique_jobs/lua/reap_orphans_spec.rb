# frozen_string_literal: true

require "spec_helper"

RSpec.describe "reap_orphans.lua" do
  subject(:reap_orphans) do
    call_script(
      :reap_orphans,
      keys: redis_keys,
      argv: argv,
    )
  end

  let(:redis_keys) do
    [
      SidekiqUniqueJobs::DIGESTS,
      SidekiqUniqueJobs::SCHEDULE,
      SidekiqUniqueJobs::RETRY,
    ]
  end
  let(:argv)     { [100] }
  let(:digest)   { "uniquejobs:digest" }
  let(:lock)     { SidekiqUniqueJobs::Lock.create(digest, job_id, lock_info) }
  let(:job_id)   { "job_id" }
  let(:item)     { raw_item }
  let(:raw_item) { { "class" => MyUniqueJob, "args" => [], "jid" => job_id, "unique_digest" => digest } }
  let(:lock_info) do
    {
      "job_id" => job_id,
      "limit" => 1,
      "lock" => :while_executing,
      "time" => now_f,
      "timeout" => nil,
      "ttl" => nil,
      "unique_args" => [],
      "worker" => "MyUniqueJob",
    }
  end

  before do
    SidekiqUniqueJobs.disable!
    lock
  end

  after do
    SidekiqUniqueJobs.enable!
  end

  context "when scheduled" do
    let(:item) { raw_item.merge("at" => Time.now.to_f + 3_600) }

    context "without scheduled job" do
      it "keeps the digest" do
        expect { reap_orphans }.to change { digests.count }.by(-1)
        expect(unique_keys).to match_array([])
      end
    end

    context "with scheduled job" do
      before { push_item(item) }

      it "keeps the digest" do
        expect { reap_orphans }.not_to change { digests.count }.from(1)
        expect(unique_keys).not_to match_array([])
      end
    end
  end

  context "when retried" do
    let(:item) { raw_item.merge("retry_count" => 2, "failed_at" => now_f) }

    context "without job in retry" do
      it "keeps the digest" do
        expect { reap_orphans }.to change { digests.count }.by(-1)
        expect(unique_keys).to match_array([])
      end
    end

    context "with job in retry" do
      before { zadd("retry", Time.now.to_f.to_s, dump_json(item)) }

      it "keeps the digest" do
        expect { reap_orphans }.not_to change { digests.count }.from(1)
        expect(unique_keys).not_to match_array([])
      end
    end
  end

  context "when digest exists in a queue" do
    context "without enqueued job" do
      it "keeps the digest" do
        expect { reap_orphans }.to change { digests.count }.by(-1)
        expect(unique_keys).to match_array([])
      end
    end

    context "with enqueued job" do
      before { push_item(item) }

      it "keeps the digest" do
        expect { reap_orphans }.not_to change { digests.count }.from(1)
        expect(unique_keys).not_to match_array([])
      end
    end
  end
end
