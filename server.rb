require 'houston'
require 'httparty'

class PushApp < Sinatra::Base

    set :bind, '0.0.0.0'
    
    before do
	content_type 'application/json'
    end
    
    get '/send_push' do
        seeker_id = params['seeker_id'] || ''
        posting_id = params['posting_id'] || ''
        if seeker_id.empty? || posting_id.empty?
            puts 'rendering error'
            status 400
            json = { 
                  :status => :error, 
                  :message => "Missing seeker_id or posting_id",
                }.to_json
                body json
                return
        end
    
        url = "http://jsmpi.snagqa.corp:7310/v1/jobs/#{posting_id}"
        response = HTTParty.get(url)
        parsed_response = response.parsed_response
    
        image_url = response["JobDetailGetResponse"]["Image"]["Logo"]
        company_name = response["JobDetailGetResponse"]["Company"]
        job_title = response["JobDetailGetResponse"]["JobTitle"]
        location_name = response["JobDetailGetResponse"]["LocationName"]
        lat = response["JobDetailGetResponse"]["Latitude"].to_f
        long = response["JobDetailGetResponse"]["Longitude"].to_f
    
        # Environment variables are automatically read, or can be overridden by any specified options. You can also
        # conveniently use `Houston::Client.development` or `Houston::Client.production`.
        apn = Houston::Client.development
        apn.certificate = File.read("push_apply.pem")

        # An example of the token sent back when a device registers for notifications
        token = "<e96802fe 4dd83e46 e8cc80c2 34e9c958 89128ded e6fc3bd4 ffd950e5 de6c4ec3>"

        # Create a notification that alerts a message to the user, plays a sound, and sets the badge on the app
        notification = Houston::Notification.new(device: token)
        notification.alert = "You have been invited to apply as a #{job_title} at #{company_name} - #{location_name}"

        # Notifications can also change the badge count, have a custom sound, have a category identifier, indicate available Newsstand content, or pass along arbitrary data.
        notification.category = "oneClickApply"
        notification.custom_data = { lat: lat,
                                     long: long,
                                     jobseeker: "#{seeker_id}",
                                     posting_id: "#{posting_id}",
                                     logo: "#{image_url}"
                                   }

        notification.mutable_content = true

        # And... sent! That's all it takes.
        apn.push(notification)
	
	status 200
        body notification.payload.to_json
    end
end
