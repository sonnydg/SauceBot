# SauceBot Monument Module Base

Sauce = require './sauce'
db    = require './saucedb'
io    = require './ioutil'

{Module} = require './module'

{ # Import DTO classes
    ArrayDTO,
    ConfigDTO,
    HashDTO,
    EnumDTO
} = require './dto'


# Preset strings
exports.strings = {
    'err-usage'             : 'Usage: @1@'
    'err-unknown-block'     : 'Unknown block "@1@"'
    'err-no-block-specified': 'No block specified'

    'action-added'  : 'Added @1@.'
    'action-removed': 'Removed @1@.'
    'action-cleared': 'Cleared.'

    'list-none'  : 'None'
    'list-blocks': 'Blocks: @1@'
}


class Monument extends Module
    constructor: (@channel, @name, @blocks, @usage) ->
        super @channel
        @command = @name.toLowerCase()

        @obtained = new ArrayDTO @channel, @command, 'block'
        
        @blocksLC = (block.toLowerCase() for block in @blocks)
        
        
    save: ->
        io.module "[#{@name}] Saving #{@channel.name} ..."
       
        # Set the data to the channel's obtained blocks
        @obtained.save()
        
    
    load: ->
        @registerHandlers()
        
        # Load monument data
        @obtained.load()
        
        @regVar @command, (user, args, cb) =>
            if not args[0] or args[0] is 'list'
                return cb @getBlockString()
            
            cb switch args[0]
                when 'count'     then @obtained.get().length
                when 'total'     then @blocks.length
                when 'remaining' then @blocks.length - @obtained.get().length
                else  'undefined'
            
        
    registerHandlers: ->
        @regCmd "#{@command}",        Sauce.Level.Mod, (user,args,bot) =>
            @cmdMonument user, args, bot
        @regCmd "#{@command} clear",  Sauce.Level.Mod, (user,args,bot) =>
            @cmdMonumentClear user, args, bot
        @regCmd "#{@command} remove", Sauce.Level.Mod, (user,args,bot) =>
            @cmdMonumentRemove user, args, bot
        

    getMonumentState: ->
        @str('list-blocks', @getBlockString())
        

    getBlockString: ->
        obtained = (block for block in @blocks when block.toLowerCase() in @obtained.get())
        obtained.join(', ') or @str('list-none')


    # !<name> - Print monument
    # !<name> <block> - Add the block to the obtained-list
    cmdMonument: (user, args, bot) ->
        unless args[0]?
            return bot.say @getMonumentState()
        
        block = args[0].toLowerCase()
        idx   = @blocksLC.indexOf block
        
        unless (idx >= 0)
            return @say bot, @str('err-unknown-block', block) + '. ' + @str('err-usage', @usage)
        
        @obtained.add block unless block in @obtained.get()
        @say bot, @str('action-added', @blocks[idx])


    # !<name> clear - Clear the monument
    cmdMonumentClear: (user, args, bot) ->
        @obtained.clear()
        @say bot, @str('action-cleared')


    # !<name> remove <block> - Removes the block from the obtained-list
    cmdMonumentRemove: (user, args, bot) ->
        unless args[0]?
            return @say bot, @str('err-no-block-specified') + '. ' + @str('err-usage', '!' + @command + ' remove <block>')
        
        block = args[0].toLowerCase()
        idx   = @blocksLC.indexOf block
        
        unless (idx >= 0)
            return @say bot, @str('err-unknown-block', block)
        
        @obtained.remove block
        @say bot, @str('action-removed', @blocks[idx])


    say: (bot, msg) ->
        bot.say '[' + @name + '] ' + msg


exports.Monument = Monument
