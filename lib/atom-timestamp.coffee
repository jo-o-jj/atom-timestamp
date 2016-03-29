moment = require 'moment'
{CompositeDisposable} = require 'atom'

module.exports = AtomTimestamp =
  config:
    timestampPrefix:
      type: 'string'
      default: 'Time-stamp:[ \\t]+["<]?'
    timestampSuffix:
      type: 'string'
      default: '[">]?$'
    timestampFormats:
      title: 'Timestamp Formats'
      description: 'Specify format-string for parsing timestamp. Use [Moment.js format](http://momentjs.com/docs/#/displaying/format/)'
      type: 'array'
      default: [
        'MMM DD YYYY'
        'YYYY-MM-DD HH:mm:ss'
        'YYYY-MM-DD'
        'YYYYMMDD'
      ]
      items:
        type: 'string'
    numberOfLines:
      description: 'Specity number of lines to search timestamp comments from the beginning.'
      type: 'integer'
      default: 8
      minimum: 1
    updateOnSave:
      title: 'Auto-run update on save'
      type: 'boolean'
      default: true

  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-timestamp:update-timestamp': =>
        if editor = atom.workspace.getActiveTextEditor()
          @updateTimestamp editor

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @subscriptions.add editor.getBuffer().onWillSave =>
        if atom.config.get 'atom-timestamp.updateOnSave'
          @updateTimestamp editor

  deactivate: ->
    @subscriptions.dispose()
    @subscriptions = null

  updateTimestamp: (editor) ->
    scanRange = [[0, 0], [atom.config.get('atom-timestamp.numberOfLines'), 0]]
    prefix = new RegExp atom.config.get('atom-timestamp.timestampPrefix'), 'g'
    suffix = new RegExp atom.config.get('atom-timestamp.timestampSuffix')
    formats = atom.config.get 'atom-timestamp.timestampFormats'

    buffer = editor.getBuffer()
    buffer.transact ->
      buffer.scanInRange prefix, scanRange, ({range}) ->
        endPos = range.end
        lineText = buffer.lineForRow(endPos.row)
        m = suffix.exec lineText.substring(endPos.column)
        t = moment lineText.substr(endPos.column, m.index), formats, true
        return unless t.isValid()

        scopeDescriptor = editor.scopeDescriptorForBufferPosition endPos
        return if scopeDescriptor.getScopesArray().every (s) ->
          !/^comment|text\.plain/.test(s)

        rep = lineText.substring(0, endPos.column) + moment().format(t.creationData().format) + lineText.substring(endPos.column + m.index)
        buffer.setTextInRange buffer.rangeForRow(endPos.row), rep
