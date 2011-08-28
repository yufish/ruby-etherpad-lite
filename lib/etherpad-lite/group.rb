module EtherpadLite
  # A Group of Pads
  class Group
    include Padded

    GROUP_ID_REGEX = /^g\.[^\$]+/
    METHOD_CREATE = 'createGroup'
    METHOD_MAPP = 'createGroupIfNotExistsFor'
    METHOD_DELETE = 'deleteGroup'
    METHOD_PADS = 'listPads'

    attr_reader :id, :instance, :mapper

    # Creates a new Group. Optionally, you may pass the :mapper option your third party system's group id.
    # This will allow you to find your Group again later using the same identifier as your foreign system.
    # If you pass the mapper option, the method behaves like "create group for <mapper> if it doesn't already exist".
    # 
    # Options:
    #  mapper => your foreign group id
    def self.create(instance, options={})
      id = options[:mapper] \
        ? instance.call(METHOD_MAPP, :groupMapper => options[:mapper])[:groupID] \
        : instance.call(METHOD_CREATE)[:groupID]
      new instance, id, options
    end

    # Instantiates a Group object (presumed to already exist.)
    # 
    # Options:
    #  mapper => the foreign id it's mapped to
    def initialize(instance, id, options={})
      @instance = instance
      @id = id
      @mapper = options[:mapper]
    end

    # Returns the Pad with the given id, creating it if it doesn't already exist.
    # This requires an HTTP request, so if you *know* the Pad already exists, use Instance#get_pad instead.
    def pad(id)
      super groupify_pad_id(id), :group => self
    end

    # Returns the Pad with the given id (presumed to already exist).
    # Use this instead of Instance#pad when you *know* the Pad already exists; it will save an HTTP request.
    def get_pad(id)
      super groupify_pad_id(id), :group => self
    end

    # Creates and returns a Pad with the given id.
    # 
    # Options:
    #  text => 'initial Pad text'
    def create_pad(id, options={})
      options[:groupID] = @id
      super id, options
    end

    # Returns an array of all the Pads in this Group.
    def pads
      pad_ids.map { |id| Pad.new(@instance, id, :group => self) }
    end

    # Returns an array of all the Pad ids in this Group.
    def pad_ids
      instance.call(METHOD_PADS, :groupID => @id)[:padIDs].keys
    end

    # Deletes the Group.
    def delete
      instance.call(METHOD_DELETE, :groupID => @id)
    end

    private

    # Prepend the group_id to the pad name
    def groupify_pad_id(pad_id)
      "#{@id}$#{pad_id}"
    end
  end
end
