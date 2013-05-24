# encoding: utf-8
#
# Jekyll big_group page generator.
# http://recursive-design.com/projects/jekyll-plugins/
#
# Version: 0.1.4 (201101061053)
#
# Copyright (c) 2010 Dave Perrett, http://recursive-design.com/
# Licensed under the MIT license (http://www.opensource.org/licenses/mit-license.php)
#
# A generator that creates big_group pages for jekyll sites.
#
# Included filters :
# - big_group_links:      Outputs the list of big_groups as comma-separated <a> links.
# - date_to_html_string: Outputs the post.date as formatted html, with hooks for CSS styling.
#
# Available _config.yml settings :
# - big_group_dir:          The subfolder to build big_group pages in (default is 'big_groups').
# - big_group_title_prefix: The string used before the big_group name in the page title (default is
#                          'Big_group: ').

module Jekyll

  # The Big_groupIndex class creates a single big_group page for the specified big_group.
  class Big_groupIndex < Page

    # Initializes a new Big_groupIndex.
    #
    #  +base+         is the String path to the <source>.
    #  +big_group_dir+ is the String path between <source> and the big_group folder.
    #  +big_group+     is the big_group currently being processed.
    def initialize(site, base, big_group_dir, big_group, title)
      @site = site
      @base = base
      @dir  = big_group_dir
      @name = 'index.html'
      self.process(@name)
      # Read the YAML data from the layout page.
      self.read_yaml(File.join(base, '_layouts'), 'big_group_index.html')
      self.data['big_group']    = big_group
      # Set the title for this page.
      title_prefix             = site.config['big_group_title_prefix'] || 'Big_group: '
      self.data['title']       = "#{title_prefix}#{title}"
      # Set the meta-description for this page.
      meta_description_prefix  = site.config['big_group_meta_description_prefix'] || 'Big_group: '
      self.data['description'] = "#{meta_description_prefix}#{title}"
    end

  end

  # The Big_groupFeed class creates an Atom feed for the specified big_group.
  class Big_groupFeed < Page

    # Initializes a new Big_groupFeed.
    #
    #  +base+         is the String path to the <source>.
    #  +big_group_dir+ is the String path between <source> and the big_group folder.
    #  +big_group+     is the big_group currently being processed.
    def initialize(site, base, big_group_dir, big_group, title)
      @site = site
      @base = base
      @dir  = big_group_dir
      @name = 'atom.xml'
      self.process(@name)
      # Read the YAML data from the layout page.
      self.read_yaml(File.join(base, '_includes/custom'), 'big_group_feed.xml')
      self.data['big_group']    = big_group
      # Set the title for this page.
      title_prefix             = site.config['big_group_title_prefix'] || 'Big_group: '
      self.data['title']       = "#{title_prefix}#{title}"
      # Set the meta-description for this page.
      meta_description_prefix  = site.config['big_group_meta_description_prefix'] || 'Big_group: '
      self.data['description'] = "#{meta_description_prefix}#{title}"

      # Set the correct feed URL.
      self.data['feed_url'] = "#{big_group_dir}/#{name}"
    end

  end

  # The Site class is a built-in Jekyll class with access to global site config information.
  class Site

    # Creates an instance of Big_groupIndex for each big_group page, renders it, and
    # writes the output to a file.
    #
    #  +big_group_dir+ is the String path to the big_group folder.
    #  +big_group+     is the big_group currently being processed.
    def write_big_group_index(big_group_dir, big_group, title)
      index = Big_groupIndex.new(self, self.source, big_group_dir, big_group, title)
      index.render(self.layouts, site_payload)
      index.write(self.dest)
      # Record the fact that this page has been added, otherwise Site::cleanup will remove it.
      self.pages << index

      # Create an Atom-feed for each index.
      if self.config['big_group_feeds']
        feed = Big_groupFeed.new(self, self.source, big_group_dir, big_group, title)
        feed.render(self.layouts, site_payload)
        feed.write(self.dest)
        # Record the fact that this page has been added, otherwise Site::cleanup will remove it.
        self.pages << feed
      end
    end


    # Loops through the list of big_group pages and processes each one.
    def write_big_group_indexes
      if self.layouts.key? 'big_group_index'
        dir = self.config['big_group_dir']
        self.big_groups.keys.each do |big_group|
          if big_group =~ /(.+)\[(.+)\]/
            slug = $1.strip
            title = $2.strip
          else
            slug = title = big_group
          end
          cat_dir = slug.gsub(/_|\P{Word}/, '-').gsub(/-{2,}/, '-').downcase
          cat_dir = File.join(dir, cat_dir) unless dir.nil? or dir.empty?
          self.write_big_group_index(cat_dir, big_group, title)
        end

      # Throw an exception if the layout couldn't be found.
      else
        raise <<-ERR


===============================================
 Error for big_group_generator.rb plugin
-----------------------------------------------
 No 'big_group_index.hmtl' in source/_layouts/
 Perhaps you haven't installed a theme yet.
===============================================

ERR
      end
    end
  end


  # Jekyll hook - the generate method is called by jekyll, and generates all of the big_group pages.
  class GenerateCategories < Generator
    safe true
    priority :low

    def generate(site)
      site.write_big_group_indexes
    end

  end


  # Adds some extra filters used during the big_group creation process.
  module Filters

    # Outputs a list of big_groups as comma-separated <a> links. This is used
    # to output the big_group list for each post on a big_group page.
    #
    #  +big_groups+ is the list of big_groups to format.
    #
    # Returns string
    #
    def big_group_links(big_groups)
      big_groups = big_groups.sort!.map { |c| big_group_link c }

      case big_groups.length
      when 0
        ""
      when 1
        big_groups[0].to_s
      else
        "#{big_groups[0...-1].join(', ')}, #{big_groups[-1]}"
      end
    end

    # Outputs a single big_group as an <a> link.
    #
    #  +big_group+ is a big_group string to format as an <a> link
    #
    # Returns string
    #
    def big_group_link(big_group)
      if big_group =~ /(.+)\[(.+)\]/
        slug = $1.strip
        title = $2.strip
      else
        slug = title = big_group
      end
      dir = @context.registers[:site].config['big_group_dir']
      url = slug.gsub(/_|\P{Word}/, '-').gsub(/-{2,}/, '-').downcase
      url = "#{dir}/#{url}" unless dir.nil? or dir.empty?
      "<a class='big_group' href='/#{url}/'>#{title}</a>"
    end

    # Outputs the post.date as formatted html, with hooks for CSS styling.
    #
    #  +date+ is the date object to format as HTML.
    #
    # Returns string
    def date_to_html_string(date)
      string = <<HTML.strip
<span class='month'>#{date.strftime('%b').upcase}</span>
#{date.strftime('<span class="day">%d</span>')}
#{date.strftime('<span class="year">%Y</span>')}
HTML
    end

  end

end

    def parse_big_group
      { slug: slug, title: title }
    end
