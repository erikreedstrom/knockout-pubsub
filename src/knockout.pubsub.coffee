__ko_registry__ = {}
__ko_queue__ = {}

ko.extenders.publish = (target, key) ->

  # check for existing observable, or set if non-existent
  if(__ko_registry__[key])
    throw "Only one observable registry is allowed per key."
  __ko_registry__[key] = target

  # subscribe all pending subscriptions
  ko.extenders.subscribe(queued, key) for queued in (__ko_queue__[key] || [])
  # removed any queued observables that have been subscribed
  delete __ko_queue__[key]

  # return target
  target

ko.extenders.subscribe = (target, key) ->

  # Pull published observable from registry.
  published = __ko_registry__[key]
  if(!published)
    # If no published observable, queue up subscribers.
    (__ko_queue__[key] ||= []).push(target)
    # Return target and end operation.
    return target

  # Otherwisem, check if published is an observable array
  isArray = published() and published.hasOwnProperty("indexOf")

  # Set up subscription.
  published.subscribe((newValue) ->
    if(isArray)
      # Check to see if the values of the arrays are different.
      if !compareArrays(target(), newValue)
        # Update value if different.
        target(newValue[0..])
    else
      # Update value.
      target(newValue) if target() isnt newValue
  )

  if(isArray)
    # Clone array so operations to the underlying array do not affect the subscribed value.
    target(published()[0..]) unless published().length is 0
  else
    target(published()) if published() and target() isnt published()

  # return target
  target

compareArrays = (list1, list2) ->
  # Return true if arrays are identical.
  return true if list1 is list2

  # Return false if only one array is null or undefined.
  return false if (!list1 and list2) or (list1 and !list2)

  # Return false if lists have different lengths.
  return false if list1.length isnt list2.length

  # Return true if both lengths are 0.
  return true if list1.length is 0 and list2.length is 0

  # Return false if any element in list2 doesn't equal the corresponding element in list1
  return false for element, i in list2 when list1[i] isnt element

  true