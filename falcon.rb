#!/usr/bin/env -S falcon host
# frozen_string_literal: true

load :rack, :supervisor

hostname = File.basename(__dir__)
rack hostname do
	cache true
  # endpoint(Async::HTTP::Endpoint.parse("http://127.0.0.1:3001"))
end

supervisor
