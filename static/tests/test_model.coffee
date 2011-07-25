
$(document).ready ->
  
  tests_path = '/tests/'
  
  module 'mobone.model', teardown: -> 
    window.localStorage.clear()
    $.mockjaxClear()
  
  
  test "Fetch a stored `LocalModel`.", ->
    
    class LM extends mobone.model.LocalModel
      storage_name: 'test'
    
    class LC extends mobone.model.LocalCollection
      storage_name: 'test'
      model: LM
    
    instance = new LM 
      id: 'a', 
      value: 'a'
    instance.save()
    
    instance2 = new LM id: 'a'
    instance2.fetch()
    
    value = instance2.get 'value'
    equal value, 'a'
    
  
  asyncTest "`LocalModel` tracks storage updates.", ->
    
    class LM extends mobone.model.LocalModel
      storage_name: 'test'
      track_changes: true
    
    instance = new LM
      id: 'a'
      value: 'foo'
    instance.save()
    
    $('body').append $ '<iframe id="test-storage-event-iframe"></iframe>'
    iframe = $ 'iframe#test-storage-event-iframe'
    iframe.attr 'src', "#{tests_path}html/test_model_update.html"
    iframe.load ->
      setTimeout ->
          value = instance.get 'value'
          equal value, 'iframe'
          iframe.remove()
        , 0
      start()
    
    
    
  
  test "Stored `LocalModel` is fetched by `LocalCollection`.", ->
    
    class LM extends mobone.model.LocalModel
      storage_name: 'test'
    
    class LC extends mobone.model.LocalCollection
      storage_name: 'test'
      model: LM
    
    collection = new LC
    instance = new LM
      id: 'a'
      value: 'a'
    instance.save()
    collection.fetch()
    
    instance = collection.get 'a'
    value = instance.get 'value' if instance?
    equal value, 'a'
    
  
  asyncTest "`LocalCollection` tracks adds.", ->
    
    class LM extends mobone.model.LocalModel
      storage_name: 'test'
    
    
    class LC extends mobone.model.LocalCollection
      storage_name: 'test'
      track_changes: true
      model: LM
    
    
    collection = new LC
    
    $('body').append $ '<iframe id="test-storage-event-iframe"></iframe>'
    iframe = $ 'iframe#test-storage-event-iframe'
    iframe.attr 'src', "#{tests_path}html/test_collection_add.html"
    iframe.load ->
      setTimeout ->
          model = collection.get 'n'
          value = model.get 'value' if model?
          equal value, 'n'
          iframe.remove()
        , 0
      start()
    
    
  
  asyncTest "`LocalCollection` tracks removes.", ->
    
    class LM extends mobone.model.LocalModel
      storage_name: 'test'
    
    
    class LC extends mobone.model.LocalCollection
      storage_name: 'test'
      track_changes: true
      model: LM
    
    collection = new LC
    instance = new LM
      id: 'n'
      value: 'n'
    instance.save()
    collection.fetch()
    
    value = instance.get 'value' if instance?
    equal value, 'n'
    
    $('body').append $ '<iframe id="test-storage-event-iframe"></iframe>'
    iframe = $ 'iframe#test-storage-event-iframe'
    iframe.attr 'src', "#{tests_path}html/test_collection_remove.html"
    iframe.load ->
      setTimeout ->
          model = collection.get 'n'
          equal model, undefined
          iframe.remove()
        , 0
      start()
    
    
  
  asyncTest "Fetch a stored `SeverBackedLocalModel`.", ->
    
    class SBLM extends mobone.model.ServerBackedLocalModel
      storage_name: 'test'
      urlRoot: '/api/example'
    
    $.mockjax
      url: '/api/example/a'
      dataType: 'json'
      responseText:
        id: '1'
        value: 'foo'
    
    
    instance = new SBLM id: 'a'
    instance.fetch
      success: ->
        value = instance.get 'value'
        equal value, 'foo'
        start()
      
    
  
  asyncTest "A stored `SeverBackedLocalModel` is cached locally.", ->
    
    class LM extends mobone.model.LocalModel
      storage_name: 'test'
    
    class SBLM extends mobone.model.ServerBackedLocalModel
      storage_name: 'test'
      urlRoot: '/api/example'
    
    $.mockjax
      url: '/api/example/a'
      dataType: 'json'
      responseText:
        id: 'a', 
        value: 'foo'
      
    
    instance = new SBLM
      id: 'a', 
      value: 'foo'
    instance.save {},
      success: ->
        instance = new LM id: 'a'
        instance.fetch()
        
        value = instance.get 'value'
        equal value, 'foo'
        
        start()
        
    
    
  
  test "`ServerBackedLocalCollection` sync fetch from local storage.", ->
    
    class LM extends mobone.model.LocalModel
      storage_name: 'test'
    
    instance = new LM 
      id: 'a', 
      value: 'foo'
    instance.save()
    
    class SBLC extends mobone.model.ServerBackedLocalCollection
      storage_name: 'test'
      url: '/api/examples'
    
    $.mockjax
      url: '/api/examples'
      dataType: 'json'
      responseText: []
    
    collection = new SBLC
    collection.fetch 'add': true
    
    instance = collection.get 'a'
    value = instance.get 'value' if instance?
    equal value, 'foo'
    
  
  asyncTest "`ServerBackedLocalCollection` async fetch from server.", ->
    
    class SBLC extends mobone.model.ServerBackedLocalCollection
      storage_name: 'test'
      url: '/api/examples'
    
    $.mockjax
      url: '/api/examples'
      dataType: 'json'
      responseText: [{id: 'a', value: 'foo'}]
    
    collection = new SBLC
    collection.fetch
      success: ->
        instance = collection.get 'a'
        value = instance.get 'value' if instance?
        equal value, 'foo'
        start()
        
      
    
    
  
  asyncTest "`ServerBackedLocalCollection` fetch from local and server.", ->
    
    class LM extends mobone.model.LocalModel
      storage_name: 'test'
    
    instance = new LM 
      id: 'a', 
      value: 'foo'
    instance.save()
    
    class SBLC extends mobone.model.ServerBackedLocalCollection
      storage_name: 'test'
      url: '/api/examples'
    
    $.mockjax
      url: '/api/examples'
      dataType: 'json'
      responseText: [{id: 'b', value: 'bar'}]
    
    collection = new SBLC
    collection.fetch
      success: ->
        b = collection.get 'b'
        value = b.get 'value' if b?
        equal value, 'bar'
        start()
      
    
    a = collection.get 'a'
    value = a.get 'value' if a?
    equal value, 'foo'
    
  
  asyncTest "`ServerBackedLocalCollection` overrides local results.", ->
    
    class LM extends mobone.model.LocalModel
      storage_name: 'test'
    
    instance = new LM 
      id: 'a', 
      value: 'foo'
    instance.save()
    
    class SBLC extends mobone.model.ServerBackedLocalCollection
      storage_name: 'test'
      url: '/api/examples'
    
    $.mockjax
      url: '/api/examples'
      dataType: 'json'
      responseText: [{id: 'a', value: 'bar'}]
    
    collection = new SBLC
    collection.fetch
      success: ->
        a = collection.get 'a'
        value = a.get 'value' if a?
        equal value, 'bar'
        start()
      
    
  
  
