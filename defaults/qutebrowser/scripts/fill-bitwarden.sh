# The autofill functionality of this script was taken from
# https://github.com/qutebrowser/qutebrowser/blob/master/misc/userscripts/password_fill

set -e

QUTE_WRONG_MASTER_PASS_MSG="Invalid master password"
QUTE_WRONG_SESSION_KEY_MSG="Invalid session key"
QUTE_NO_LOGIN_FOUND_MSG="No logins available for '$QUTE_URL'"
QUTE_NO_FORMS_FOUND_MSG="No login forms were found"

# TODO:
# 1. N26 password is fetched correctly but it doesn't get inputted into the
#    password field
# 2. wise.com password gets inputted into the password field, but wise
#    complains about password not being given. It needs to be changed (e.g. by
#    adding and deleting a character) before it becomes valid. Also happens on
#    bwin.it

function qute_echo_error() {
  echo "message-error \"$1\"" >> "$QUTE_FIFO"
}

{
  key_id="$(keyctl request user bw_session)"
  session_key="$(keyctl pipe "$key_id")"
} || {
  bw_password="$(dmenu-xembed-qute -P -p "Master password> ")" \
    || exit 0
  session_key="$(bw unlock --raw "$bw_password")" \
    || { qute_echo_error "$QUTE_WRONG_MASTER_PASS_MSG" && exit 0; }
  keyctl add user bw_session "$session_key" @u
}

items="$(bw list items --session "$session_key" --url "$QUTE_URL")" \
  || { qute_echo_error "$QUTE_WRONG_SESSION_KEY_MSG" && exit 0; }

case "$(echo "$items" | jq length)" in
  0)
    qute_echo_error "$QUTE_NO_LOGIN_FOUND_MSG" && exit 0
    ;;
  1)
    login="$(echo "$items" | jq '.[0].login')"
    ;;
  *)
    name="$(\
      echo "$items" \
      | jq -r '.[].name' \
      | dmenu-xembed-qute -l 5 -p "Login> " \
      || exit 0 \
    )"
    login="$(echo "$items" | jq ".[] | select(.name == \"$name\") | .login")"
    ;;
esac

username="$(echo "$login" | jq -r '.username')"
password="$(echo "$login" | jq -r '.password')"

function javascript_escape() {
  sed "s,[\\\\'\"],\\\\&,g" <<< "$1"
}

function js() {
cat <<EOF
  function isVisible(elem) {
      var style = elem.ownerDocument.defaultView.getComputedStyle(elem, null);
      if (style.getPropertyValue("visibility") !== "visible"
          || style.getPropertyValue("display") === "none"
          || style.getPropertyValue("opacity") === "0") {
          return false;
      }
      return elem.offsetWidth > 0 && elem.offsetHeight > 0;
  };
  function hasPasswordField(form) {
      var inputs = form.getElementsByTagName("input");
      for (var j = 0; j < inputs.length; j++) {
          var input = inputs[j];
          if (input.type == "password") {
              return true;
          }
      }
      return false;
  };
  function loadData2Form (form) {
      var inputs = form.getElementsByTagName("input");
      for (var j = 0; j < inputs.length; j++) {
          var input = inputs[j];
          if (isVisible(input)
              && (input.type == "text" || input.type == "email")) {
              input.focus();
              input.value = "$(javascript_escape "${username}")";
              input.blur();
          }
          if (input.type == "password") {
              input.focus();
              input.value = "$(javascript_escape "${password}")";
              input.blur();
          }
      }
  };
  var forms = document.getElementsByTagName("form");
  for (i = 0; i < forms.length; i++) {
      if (hasPasswordField(forms[i])) {
          loadData2Form(forms[i]);
      }
  }
EOF
}

function printjs() {
  js | sed 's,//.*$,,' | tr '\n' ' '
}

echo "jseval --quiet $(printjs)" >> "$QUTE_FIFO"
