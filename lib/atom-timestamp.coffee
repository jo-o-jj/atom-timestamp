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
    prefix = new RegExp atom.config.get('atom-timestamp.timestampPrefix'), 'g'
    suffix = new RegExp atom.config.get('atom-timestamp.timestampSuffix')
    formats = atom.config.get 'atom-timestamp.timestampFormats'

    buffer = editor.getBuffer()
    buffer.transact ->
      buffer.scan prefix, ({computedRange, lineText}) ->
        endPos = computedRange.end
        m = suffix.exec lineText.substring(endPos.column)
        t = moment lineText.substr(endPos.column, m.index), formats, true
        return unless t.isValid()

        scopeDescriptor = editor.scopeDescriptorForBufferPosition endPos
        return if scopeDescriptor.getScopesArray().every (s) ->
          !/^comment|text\.plain/.test(s)

        rep = lineText.substring(0, endPos.column) + moment().format(t.creationData().format) + lineText.substring(endPos.column + m.index)
        buffer.setTextInRange buffer.rangeForRow(endPos.row), rep
