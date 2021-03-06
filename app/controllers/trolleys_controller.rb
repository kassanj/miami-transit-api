class TrolleysController < ApplicationController
  START_TIME = '06:30:00'
  END_TIME   = '23:00:00'

  def index
    @translator = TrolleyTranslator.new vehicles: vechicles_data, routes: routes_data, stops: stops_data

    respond_to do |format|
      format.json { render json: @translator.to_gtfs(encode: false) }
      format.gtfsrt { send_data @translator.to_gtfs }
    end
  end

  # .txt files

  def agency
    csv_response = CSV.generate do |csv|
      csv << %w[agency_id agency_name agency_url agency_timezone agency_lang agency_phone agency_fare_url]
      csv << [
        "",
        "City Of Miami",
        "http://www.miamigov.com/trolley/",
        "America/New York",
        "en",
        "",
        ""
      ]
    end
    render text: csv_response
  end

  def stops
    csv_response = CSV.generate do |csv|
      csv << %w[stop_id stop_name stop_lat stop_lon]
      stops_data.map do |stop|
        csv << %w[id name lat lng].map { |att| stop[att] }
      end
    end
    render text: csv_response
  end

  def routes
    csv_response = CSV.generate do |csv|
      csv << %w[route_id route_short_name route_long_name route_type]
      routes_data.map do |route|
        csv << [route['id'], route['name'], route['name'], 3]
      end
    end
    render text: csv_response
  end

  def trips
    csv_response = CSV.generate do |csv|
      csv << %w[route_id service_id trip_id trip_headsign]
      routes_data.map do |route|
        csv << [route['id'], 1, route['id'], route['name']]
      end
    end
    render text: csv_response
  end

  def calendar
    csv_response = CSV.generate do |csv|
      csv << %w[service_id monday tuesday wednesday thursday friday saturday sunday start_date end_date]
      csv << %w[1          1      1       1         1        1      1        1      20150101 20151231]
    end
    render text: csv_response
  end

  def stop_times
    csv_response = CSV.generate do |csv|
      csv << %w[trip_id arrival_time departure_time stop_id stop_sequence]
      routes_data.each do |route|
        route['stops'].each_with_index do |stop_id, i|
          time = if i == 0
            START_TIME
          elsif i == route['stops'].length - 1
            END_TIME
          end
          csv << [route['id'], time, time, stop_id, i]
        end
      end
    end
    render text: csv_response
  end

  def frequencies
    csv_response = CSV.generate do |csv|
      csv << %w[trip_id start_time end_time headway_secs]
      routes_data.each do |route|
        csv << [route['id'], START_TIME, END_TIME, '900']
      end
    end
    render text: csv_response
  end

  private

  def vehicle_api
    @vehicle_api ||= MiamiCityTransit.proxy(
      service: 'get_vehicles',
      'includeETAData' => 1,
      'orderedETAArray' => 1,
      token: 'TESTING'
    )
  end

  def vechicles_data
    @vechicles_data ||= JSON.parse(vehicle_api.body)['get_vehicles']
  end

  def routes_api
    @routes_api ||= MiamiCityTransit.routes
  end

  def routes_data
    @routes_data ||= JSON.parse(routes_api.body)['get_routes']
  end

  def stops_api
    @stops_api ||= MiamiCityTransit.stops
  end

  def stops_data
    @stops_data ||= JSON.parse(stops_api.body)['get_stops']
  end
end
