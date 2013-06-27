Deface::Override.new(
    :virtual_path => 'my/account',
    :name => 'my_digest_rules',
    :insert_after => 'div.splitcontentright fieldset.box:first-child',
    :text => '<%= render "digest_rules/index" if @user.pref.digest_enabled? %>')

Deface::Override.new(
    :virtual_path => 'my/account',
    :name => 'skip_digest_notifications',
    :insert_after => 'code[erb-loud]:contains("users/mail_notifications")',
    :text => <<INCLUDES
<% if @user.pref.digest_enabled? %>
  <%= labelled_fields_for :pref, @user.pref do |pref_fields| %>
    <p><%= pref_fields.check_box :skip_digest_notifications %></p>
  <% end %>
<% end %>
INCLUDES
)
