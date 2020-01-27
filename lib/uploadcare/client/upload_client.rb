# frozen_string_literal: true

module Uploadcare
  # This is client for general uploads
  # https://uploadcare.com/api-refs/upload-api/#tag/Upload
  class UploadClient < ApiStruct::Client
    upload_api

    # https://uploadcare.com/api-refs/upload-api/#operation/baseUpload

    def upload_many(arr, **options)
      body = HTTP::FormData::Multipart.new(
        upload_params(options[:store]).merge(files_formdata(arr))
      )
      post(path: 'base/',
           headers: { 'Content-type': body.content_type },
           body: body)
    end

    # Upload files from url
    # https://uploadcare.com/api-refs/upload-api/#operation/fromURLUpload
    # options:
    # - check_URL_duplicates
    # - filename
    # - save_URL_duplicates
    # - async - returns upload token instead of upload data

    def upload_from_url(url, store: false, **options)
      body = HTTP::FormData::Multipart.new({
        'pub_key': PUBLIC_KEY,
        'source_url': url,
        'store': store
      }.merge(options))
      token_response = post(path: 'from_url/', headers: { 'Content-type': body.content_type }, body: body)
      return token_response if options[:async]

      uploaded_response = poll_upload_result(token_response.success[:token])
      return Dry::Monads::Success(uploaded_response) if uploaded_response[:status] == 'error'

      Dry::Monads::Success({ files: [uploaded_response] })
    end

    private

    def poll_upload_result(token)
      loop do
        response = get_status_response(token).value!
        break(response) if %w[success error].include?(response[:status])
        sleep 0.5
      end
    end

    def get_status_response(token)
      query_params = { token: token }
      get(path: 'from_url/status/', params: query_params)
    end

    def upload_params(store = false)
      {
        'UPLOADCARE_PUB_KEY': PUBLIC_KEY,
        'UPLOADCARE_STORE': store == true ? '1' : '0'
      }
    end

    def files_formdata(arr)
      arr.map do |file|
        [HTTP::FormData::File.new(file).filename,
         HTTP::FormData::File.new(file)]
      end .to_h
    end
  end
end
