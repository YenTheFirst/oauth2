require 'spec_helper'

describe OAuth2::Strategy::WebServer do
  let(:client) do
    cli = OAuth2::Client.new('abc', 'def', :site => 'http://api.example.com')
    cli.connection.build do |b|
      b.adapter :test do |stub|
        stub.post('/oauth/access_token') do |env|
          case @mode
            when "formencoded"
              [200, {}, 'expires_in=600&access_token=salmon&refresh_token=trout&extra_param=steve']
            when "json"
              [200, {}, '{"expires_in":600,"access_token":"salmon","refresh_token":"trout","extra_param":"steve"}']
          end
        end
      end
    end
    cli
  end
  subject { client.web_server }

  describe '#authorize_url' do
    it 'should include the client_id' do
      subject.authorize_url.should be_include('client_id=abc')
    end

    it 'should include the type' do
      subject.authorize_url.should be_include('type=web_server')
    end

    it 'should include passed in options' do
      cb = 'http://myserver.local/oauth/callback'
      subject.authorize_url(:redirect_uri => cb).should be_include("redirect_uri=#{Rack::Utils.escape(cb)}")
    end
  end

  %w(json formencoded).each do |mode|
    [false,true].each do |parse_json|
      describe "#get_access_token (#{mode}, parse_json=#{parse_json})" do
        before do
          @mode = mode
          client.json=parse_json
          @access = subject.get_access_token('sushi')
        end
  
        it 'returns AccessToken with same Client' do
          @access.client.should == client
        end
  
        it 'returns AccessToken with #token' do
          @access.token.should == 'salmon'
        end
  
        it 'returns AccessToken with #refresh_token' do
          @access.refresh_token.should == 'trout'
        end
  
        it 'returns AccessToken with #expires_in' do
          @access.expires_in.should == 600
        end
  
        it 'returns AccessToken with #expires_at' do
          @access.expires_at.should be_kind_of(Time)
        end
  
        it 'returns AccessToken with params accessible via []' do
          @access['extra_param'].should == 'steve'
        end
      end
    end
  end
end
