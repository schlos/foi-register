# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  requestor_id = $ '#request_requestor_attributes_id'
  requestor_email = $ '#request_requestor_attributes_email'
  
  $('#request_requestor_attributes_name').autocomplete({
    source: "/ajax/requestors"
  }).bind("autocompletefocus", (event, ui) ->
    requestor_email.val ui.item.email
  ).bind("autocompleteselect", (event, ui) ->
    requestor_email.attr("disabled", true).val(ui.item.email)
    requestor_id.val ui.item.id
  ).bind("change", (event) ->
    if requestor_id.val()
      requestor_id.val("")
      requestor_email.removeAttr("disabled").val("")
  )
  
  lgcs_term_id = $ '#request_lgcs_term_id'
  lgcs_term = $ '#request_lgcs_term'
  
  lgcs_term.autocomplete({
    source: "/ajax/lgcs_terms"
  })
  .bind "autocompleteselect", (event, ui) ->
    lgcs_term_id.val ui.item.id
    lgcs_term.blur()
  .bind "focus", (event) ->
    lgcs_term.val ""
    lgcs_term_id.val ""
  .bind "blur", (event) ->
    lgcs_term.val("") if !lgcs_term_id.val()
  
  state_select = $ '#request_state_attributes_id'
  state_description = $ '#state-description'
  state_select.bind "change", (ev) ->
    state_description.text(state_select.find("option[value=" + state_select.val() + "]").attr("title"))

  $('span.state').tooltip()

  # Type-ahead search when creating a new request
  tar = $("#typeahead_response")
  if tar.length > 0
    $("#request_title").keypress($.debounce( 300, () ->
      $.get("/requests/search_typeahead?q=" + encodeURIComponent(this.value), (result) ->
        if result && result.length > 0
          tar.show().html "<h2>Possibly related requests</h2>"
          $.each result, (i, e) ->
            tar.append($("<a target='other-request'/>").attr("href", "/requests/" + e.id).text(e.title), "<br>")
        else
          tar.hide()
      )
    ))

