require "boxen/preflight"
require "highline"
require "octokit"

# HACK: Unless this is `false`, HighLine has some really bizarre
# problems with empty/expended streams at bizarre intervals.

HighLine.track_eof = false

class Boxen::Preflight::Creds < Boxen::Preflight
  def ok?
    token?
  end

  def token?
    return unless config.token
    config.api.user rescue nil
  end

  def run
    console = HighLine.new

    warn "Hey, I need your current GitHub credentials to continue."

    config.login = console.ask "GitHub login: " do |q|
      q.default = config.login || config.user
      q.validate = /\A[^@]+\Z/
    end

    response = `curl -i -u #{config.login} \
      -d '{"scopes": ["repo"]}' https://api.github.com/authorizations`
    config.token = response.slice(/[0-9a-f]{40}/)

    unless token?
      puts # i <3 vertical whitespace

      abort "Sorry, I can't auth you on GitHub.",
        "Please check your credentials and teams and give it another try."
    end
  end
end
