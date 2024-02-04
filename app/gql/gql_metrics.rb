# frozen_string_literal: true

module GqlMetrics
  module_function

  Struct.new("Query", :queries, :count, :names, keyword_init: true)

  FATAL_ERROR = -1
  FATAL_NAME = "fatal"

  GRAPHQL_ERROR = 500

  def before_query(query)
    struct = _queries(selections: query.selected_operation.selections)

    Console.logger.info(self, "#{Thread.current[:rid]} post /graphql #{struct.names.join(", ")}")
  end

  def after_query(query)
    # noop
  end

  def after_query_save(query)
    begin
      struct = _queries(selections: query.selected_operation.selections)

      if query.result_values["data"].present?
        # parse data
        _status_codes = query.result_values["data"].values.map do |hash|
          hash["code"].to_i
        end
      else
        # no data, only errors
        _status_codes = struct.queries.map do |query|
          GRAPHQL_ERROR
        end

        Raven.capture_message("gql exception")
      end
    rescue StandardError => e
      Raven.capture_exception(e)

      struct = Struct::Query.new(
        queries: [
          {
            error: {
              message: e.message
            }
          }
        ],
        count: 0,
        names: [FATAL_NAME],
      )

      _status_codes = [FATAL_ERROR]
    end

    user = query.context[:current_user]
    _user_id = user&.id.to_i

    _client = query.context[:current_client].to_s

    # prometheus doesn't like arrays, so record each query separately

    # struct.names.each_with_index do |name, index|
    #   code = status_codes[index].to_i

    #   metric_data = {
    #     client: client,
    #     code: code,
    #     name: "gql/#{name}",
    #     query_count: struct.count,
    #   }

    #   _record_metric(
    #     metric_data: metric_data,
    #     time_msec: time_msec,
    #   )
    # end

    # log the request

    # _log_query(
    #   client: client,
    #   queries: struct.queries,
    #   query_names: struct.names,
    #   query_count: struct.count,
    #   status_codes: status_codes,
    #   errors: query.result["errors"] || [],
    #   user_id: user_id,
    # )
  end

  def _log_query(client:, queries:, query_count:, query_names:, status_codes:, errors:, user_id:)
    if query_count == 1
      # special case when there is only 1 query
      _query_name_key = :query_name
      _query_name_value = query_names[0]

      _status_key = :status_code
      status_value = status_codes[0]

      if status_value.to_i >= 400
        logger_method = :error
      else
        logger_method = :info
      end
    else
      _query_name_key = :query_names
      _query_name_value = query_names

      _status_key = :status_codes
      status_value = status_codes

      logger_method = :info
    end

    logger_data = {
      name: "gql/#{query_names.sort.join('/')}",
      client: client,
      query_count: query_count,
      queries: queries,
      query_name: query_names[0],
      query_names: query_names,
      status_code: status_codes[0],
      status_codes: status_codes,
      errors: errors.map{ |error| error["message"] },
      user_id: user_id,
      msec: time_msec,
    }

    Log::Factory.instance.send(logger_method, logger_data)
  end

  # build queries hash used for logging
  def _queries(selections:)
    query_struct = Struct::Query.new(
      queries: [],
      count: 0,
      names: [],
    )

    selections.each do |selection|
      key = selection.name

      children = _query_fields(
        selections: selection.selections,
      )

      query_struct.names.push(key)

      query_struct.queries.push(
        key => children
      )

      query_struct.count += 1
    end

    query_struct
  end

  def _query_fields(selections:)
    selections.reduce({}) do |hash, selection|
      key = selection.name

      if selection.respond_to?(:selections)
        children = _query_fields(
          selections: selection.selections,
        )
      else
        children = {}
      end

      hash[key] = children

      hash
    end
  end

  # def _record_metric(metric_data:, time_msec:)
  #   Prometheus::Recorder.instance.record_metric_api(
  #     data: metric_data,
  #     msec: time_msec,
  #   )
  # end

end
