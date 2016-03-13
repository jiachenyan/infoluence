class LinksController < ApplicationController
	def save_link
		return render json_error('Invalid link') if params[:link].blank?

		param_url = params[:link]
		# add http to links without it
		param_url = param_url.prepend('http://') unless param_url.match(/\Ahttps?:\/\//i)

		# look for existing with input url
		existing_link = ExternalLink.find_by_url_or_origin(param_url)
		if existing_link.present?
			existing_link.touch
			return render jsonize(existing_link.json_serialize)
		end

		# look for existing info with og
		uri = URI.parse(URI.escape(param_url))
		begin
			og_reader = Timeout.timeout(2){ OpenGraphReader.fetch!(uri) }
		rescue => e
			# error on fetch, try saving link with just url
			# timed out fetching link, try saving link with just url
			link = ExternalLink.new(url: uri.to_s, origin: param_url)
			link.add_fetch_error

			if link.save
				return render jsonize(link.json_serialize)
			else
				return render json_error(link)
			end
		end

		link_url = og_reader.og.url # og url should never be null 
		existing_link = ExternalLink.find_by_url_or_origin(link_url)
		return render jsonize(existing_link.json_serialize) if existing_link.present?

		# no existing record, save new info
		link = ExternalLink.new(url: link_url, origin: param_url)
		return render json_error(link) unless link.valid?

		# save og data to info
		link.process_link_info(og_reader)

		# process images and save link
		if link.save
			render jsonize(link.json_serialize)
		else
			render json_error(link)
		end

	rescue => e
		if !defined?(link) or link.blank?
			link = ExternalLink.new(url: param_url, origin: param_url)
		end

		link.add_fetch_error
		if link.save
			return render jsonize(link.json_serialize)
		else
			return render json_error(link)
		end
	end

	private

	def json_link_info_rescue_msg(link, reason, error_msg, *objs)
		# save link, and log exception
		if save_or_log_exc(link, "send_link_info_#{reason}_save_failed", *objs)
			# save successful, and log exception
			log_exc "send_link_info_#{reason}", link, *objs
			jsonize(link.json_serialize)
		else
			# save unsuccessful and save exception is logged
			json_error("Invalid link format, #{error_msg}", link.errors.full_messages)
		end
	end
end
