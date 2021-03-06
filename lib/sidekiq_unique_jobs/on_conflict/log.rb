# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Strategy to log information about conflict
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class Log < OnConflict::Strategy
      include SidekiqUniqueJobs::Logging

      #
      # Logs an informational message about that the job was not unique
      #
      #
      # @return [void]
      #
      def call
        log_info(<<~MESSAGE.chomp)
          Skipping job with id (#{item[JID]}) because unique_digest: (#{item[UNIQUE_DIGEST]}) already exists
        MESSAGE
      end
    end
  end
end
