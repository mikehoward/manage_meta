module ManageMeta
  def included(mod)
    mod.send(:helper_method, :render_meta) if mod.respond_to? :helper_method
  end
  
  #- initialize instance variables
  def _manage_meta_init
    return if @manage_meta_meta_hash.instance_of? Hash
    @manage_meta_meta_hash = {}

    @manage_meta_format_hash = {
      :named => '<meta name="#{name}" content="#{content}" char-encoding="utf-8" />',
      :http_equiv => '<meta http-equiv="#{name}" content="#{content}" char-encoding="utf-8" />',
      :canonical => '<link rel="canonical" href="#{content}" />',
    }

    @manage_meta_name_to_format = {}
    #-- set up http-equiv meta tags
    [:accept, :accept_charset, :accept_encoding, :accept_language, :accept_ranges,
      :age,  :allow,  :authorization,  :cache_control,  :connecting, :content_encoding,
      :content_language, :content_length, :content_location, :content_md5,  :content_range,
      :content_type, :date, :etag, :expect, :expires,  :from, :host, :if_match, :if_modified_since,
      :if_none_match,  :if_range, :if_unmodified_since,  :last_modified,  :location,
      :max_forwards, :pragma, :proxy_authenticate, :proxy_authorization,  :range,  :referer,
      :retry_after,  :server, :te, :trailer,  :transfer_encoding,  :upgrade,  :user_agent,
      :vary, :via,  :warning,  :www_authenticate, ].each { |name| @manage_meta_name_to_format[name] = :http_equiv }
    # set up Google's canonical link tag
    [:canonical].each { |name| @manage_meta_name_to_format[name] = :canonical }
    # set up normal meta tags
    [:description, :keywords, :language, :robots].each { |name| @manage_meta_name_to_format[name] = :named }

    add_meta 'robots', 'index follow'
    add_meta 'generator', "Rails #{Rails.version}" if defined?(Rails)
  end
  
  #--

  #++
  # add_meta(name, value[, options]) - adds meta tag 'name' with value 'value' to meta tags to be displayed
  # add_meta(name[, options] &block) - does same thing, except value is the return value of &block
  #  Note: if no both 'value' and 'block' are given, then the content of the meta tag is the concatenation
  #         of both values.
  #  options:
  #    :format => symbol - where 'symbol' is one of :named, :http_equiv, :canonical, or a format
  #       added with 'add_meta_format'
  #    all other options keys are ignored
  #--
  def add_meta(name, opt_value = nil, options = {}, &block)
    _manage_meta_init unless @manage_meta_meta_hash.instance_of? Hash
    
    # make sure name is a string
    name = _manage_meta_name_to_sym name

    # handle optional nonsense
    case
    when opt_value.is_a?(String)
      value = opt_value
      value += yield.to_s if block_given?
    when opt_value.is_a?(Hash)
      raise ArgumentError, "Value for meta tag #{name} missing" if !block_given?
      value = yield.to_s
      options = opt_value
    when opt_value.nil?
      raise ArgumentError, "Value for meta tag #{name} missing" if !block_given?
      value = yield.to_s
    when opt_value.respond_to?(:to_s)
      value = opt_value.to_s
      value += yield.to_s if block_given?
    else
      raise ArgumentError, "add_meta(name, value[, options hash]) or add_meta(name[, option hash] do ... end)"
    end
    @manage_meta_meta_hash[name] = value

    if (options.keys - [:format]).size > 0
      raise RuntimeError, "add_meta(#{name}, ...): illegal option key(s): #{options.keys - [:format]}"
    end

    # if format is explicitly called out or if name is not yet known
    if options.has_key?(:format)
      raise RuntimeError, "Unsuported Format: #{options[:format]}: formats are #{@manage_meta_format_hash.keys.join(',')}" \
            if !@manage_meta_format_hash.has_key?(options[:format].to_sym)
      @manage_meta_name_to_format[name] = options[:format].to_sym
    elsif !@manage_meta_name_to_format.has_key?(name)
      @manage_meta_name_to_format[name] = :named
    end
  end

  #++
  # del_meta(name) - where _name_ is a string or a symbol.
  #
  # if _name_ is in @manage_meta_meta_hash, then it will be deleted
  #--
  def del_meta(name)
    _manage_meta_init unless @manage_meta_meta_hash.instance_of? Hash
    
    name = _manage_meta_name_to_sym name
    @manage_meta_meta_hash.delete name if @manage_meta_meta_hash.has_key? name
  end

  #++
  # add_meta_format(key, format)
  #
  # adds the format _format_ to @manage_meta_format_hash using the key _key_
  #--
  def add_meta_format(key, format)
    _manage_meta_init unless @manage_meta_meta_hash.instance_of? Hash
    
    key = key.to_sym
    @manage_meta_format_hash[key] = format
  end

  #++
  # render_meta
  #
  # returns a string consisting of all defined meta names in @manage_meta_meta_hash, formatted
  # using their name-specific formats and indented two spaces.
  #--
  def render_meta
    _manage_meta_init unless @manage_meta_meta_hash.instance_of? Hash
    
    '  ' + @manage_meta_meta_hash.map do |name, content|
      @manage_meta_format_hash[@manage_meta_name_to_format[name]].sub('#{name}', _manage_meta_sym_to_name(name)).sub('#{content}', content)
    end.join("\n  ") + "  \n"
  end
  
  private
  def _manage_meta_sym_to_name(sym)
    sym.to_s.split(/[_-]/).map {|x| x.capitalize }.join('-')
  end
  
  def _manage_meta_name_to_sym(name)
    name.to_s.downcase.gsub(/[-_]+/, '_').to_sym
  end

  public :add_meta, :del_meta, :add_meta_format, :render_meta
  private :_manage_meta_init, :_manage_meta_sym_to_name, :_manage_meta_name_to_sym

end