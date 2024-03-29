require 'digest'
require 'pathname'

# encoding: utf-8
#
# Jekyll publisher for privateley public posts.
#
# Version: 0.3.0
#
# Author: Brian Pearce
# Site: http://www.alwayscoding.ca
# Licensed under the MIT license (http://www.opensource.org/licenses/mit-license.php)
#
# A generator that creates privately public pages. Pages secured only by url
# obscurity. Links are published to the console during generation or via rake
# task. Links can be given to friends for previewing.

module Jekyll

  class Site
    attr_accessor :privpub_posts

    alias_method :previous_reset, :reset
    def reset
      self.privpub_posts = []
      previous_reset
    end

    alias_method :previous_render, :render
    def render
      payload = site_payload
      self.privpub_posts.each do |post|
        post.render(self.layouts, payload)
      end
      previous_render
    rescue Errno::ENOENT => e
      # ignore missing layout dir
    end

    alias_method :previous_write, :write
    def write
      self.privpub_posts.each do |post|
        post.write(self.dest)
      end
      previous_write
    end
  end

  module PrivatelyPublic

    class Post < Jekyll::Post
      def permalink
        "#{privpub_path}/#{digest}/#{CGI.escape(slug)}"
      end

      protected

      def privpub_path
        !site.config[:privpub_path].nil? ? Pathname.new("/#{site.config[:privpub_path]}").cleanpath : '/private'
      end

      def digest
        CGI.escape(Digest::SHA1.hexdigest(slug)[0...6])
      end
    end

    class Generator < Jekyll::Generator
      safe true
      priority :normal

      def read_posts(site, dir = '')
        entries = site.get_entries(dir, '_posts')

        # first pass processes, but does not yet render post content
        entries.each do |f|
          if Post.valid?(f)
            post = Post.new(site, site.source, '', f)

            if post.data.has_key?('privpub') && post.data['privpub'] == true
              site.privpub_posts << post
            end
          end
        end
      end

      def display_results(site)
        if !site.privpub_posts.empty?
          puts Jekyll.logger.message('PrivatelyPublic:', 'Generated privately public links:')

          site.privpub_posts.each do |p|
            puts Jekyll.logger.message('',  "- #{p.permalink}")
          end
        end
      end

      def generate(site)
        read_posts(site)
        display_results(site)
      end
    end

  end
end
