require "sinatra"

RE_NOTE = /\A[a-zA-Z0-9_-]{1,64}\z/
SAVE_PATH = '_tmp'

set :views, settings.root + '/templates'
set :public_folder, __dir__ + '/static'


helpers do

  def h(text)
    Rack::Utils.escape_html(text)
  end

  def random_note
    '234579abcdefghjkmnpqrstwxyz'.split('').shuffle.take(5).join
  end

  def command_line?(user_agent)
    user_agent.start_with?("curl") || user_agent.start_with?("Wget")
  end
end


get '/:note?' do
  headers(
    'Cache-Control' => 'no-cache, no-store, must-revalidate',
    'Pragma' => 'no-cache',
    'Expires' => '0',
  )

  unless RE_NOTE.match(params['note'])
    redirect to(random_note)
  end

  path = File.join(SAVE_PATH, params['note'])
  if params['raw'] && command_line?(request.user_agent)
    headers 'Content-type' => 'text/plain'
    unless File.exist?(path)
      status 404
      return ""
    end
    return File.read(path)
  end
  @content = File.exist?(path) ? File.read(path) : ''
  erb :index
end


post '/:note' do
  unless RE_NOTE.match(params['note'])
    status 400
    redirect to(random_note)
  end
  path = File.join(SAVE_PATH, params['note'])
  if params['text'].empty?
    File.remove(path) if File.exist?(path)
  else
    File.write(path, params['text'])
  end
  "ok"
end
