# Home Assistant setup

The kiosk page is driven by a single helper. You'll add a small set of helpers, automations, and (optionally) a YAML dashboard. All snippets are also collected in [`setup/ha-config.yaml`](../setup/ha-config.yaml).

## 1. Helpers

```yaml
# configuration.yaml
input_select:
  jarvis_card:
    name: "Jarvis Active Card"
    options:
      - home
      - weather
      - commute
      - listening
      - ack
      - grocery
    initial: home
    icon: mdi:robot

input_text:
  jarvis_last_speech:
    name: "Jarvis Last Speech"
    max: 255
    initial: ""
```

`input_select.jarvis_card` is the single source of truth for which face is shown. The page reactively swaps to whichever option is currently selected. `input_text.jarvis_last_speech` holds the spoken text shown on the `ack` face.

## 2. Long-lived access token

The page authenticates via WebSocket to HA. Generate a long-lived token (HA → user profile → Long-Lived Access Tokens → Create) and replace `__HA_TOKEN__` in the variant `index.html` you deploy.

For better security, make a dedicated user (Settings → People → Users → Add user, group `Users`, local-only on) and create the long-lived token while signed in as that user. The token grants only what that user can do.

## 3. Auto-reset automation (mandatory)

```yaml
# automations.yaml
- id: jarvis_card_auto_reset
  alias: Jarvis - Reset card to home after 30s
  description: When jarvis_card flips off home, reset to home after 30s
  triggers:
    - trigger: state
      entity_id: input_select.jarvis_card
      to: ~
      for:
        seconds: 30
  conditions:
    - condition: template
      value_template: "{{ trigger.to_state.state != 'home' }}"
  actions:
    - service: input_select.select_option
      target:
        entity_id: input_select.jarvis_card
      data:
        option: home
  mode: restart
```

## 4. Wire intents to flip the card

Each intent that has a dedicated face needs to flip the helper before speaking.

### Weather

```yaml
intent_script:
  RichWeather:
    description: Current weather with temperature
    action:
      - service: input_select.select_option
        target:
          entity_id: input_select.jarvis_card
        data:
          option: weather
    speech:
      text: "It's {{ states('weather.forecast_home') | replace('_',' ') }} and {{ state_attr('weather.forecast_home','temperature') | round(0) }} degrees."
```

### Commute (PATH + travel-time example)

```yaml
intent_script:
  CommuteReport:
    action:
      - service: input_select.select_option
        target:
          entity_id: input_select.jarvis_card
        data:
          option: commute
    speech:
      text: "PATH to WTC: ..."
```

### Grocery list

For the `GroceriesShoppingList` / `GroceriesListLow` / `GroceriesListOut` intents, set `option: grocery`. The page reads `sensor.groceries_low.attributes.items` (a list of `{item, status, qty}` objects).

## 5. Generic ack-fallback (catch-all)

Any TTS response that isn't already routed to a dedicated face shows up on the `ack` face. Two automations cover both Wyoming-satellite responses and HA-Cloud TTS service calls.

```yaml
- id: jarvis_ack_satellite_responding
  alias: Jarvis - Show ack when satellite goes to responding
  triggers:
    - trigger: state
      entity_id: assist_satellite.echo_show_office  # adjust to your satellite entity
      to: responding
  conditions:
    - condition: state
      entity_id: input_select.jarvis_card
      state: home
  actions:
    - service: input_text.set_value
      target:
        entity_id: input_text.jarvis_last_speech
      data:
        value: "Jarvis is responding…"
    - service: input_select.select_option
      target:
        entity_id: input_select.jarvis_card
      data:
        option: ack
  mode: single

- id: jarvis_ack_global_fallback
  alias: Jarvis - Ack any TTS-spoken text
  triggers:
    - trigger: event
      event_type: call_service
      event_data:
        domain: tts
  conditions:
    - condition: state
      entity_id: input_select.jarvis_card
      state: home
    - condition: template
      value_template: "{{ trigger.event.data.service_data.message is defined and trigger.event.data.service_data.message | string | length > 0 }}"
  actions:
    - service: input_text.set_value
      target:
        entity_id: input_text.jarvis_last_speech
      data:
        value: "{{ trigger.event.data.service_data.message | string }}"
    - service: input_select.select_option
      target:
        entity_id: input_select.jarvis_card
      data:
        option: ack
  mode: single
```

## 6. Touch interactions (touch variants only)

The touch variants call HA services directly via the open WebSocket:

| Gesture | Action |
|---|---|
| Tap "Outside" temp on home | Flip to weather |
| Tap "28 Liberty" / "30 Irving" cells | Flip to commute |
| Tap empty area on weather/commute/ack | Back to home |
| Tap commute hero number | Toggle which destination is shown |
| Swipe a grocery row > 35% width | Calls `rest_command.groceries_remove_from_list` |

For grocery swipe-to-remove to actually persist, you need a `rest_command` configured on the HA side that talks to whatever inventory backend you use:

```yaml
rest_command:
  groceries_remove_from_list:
    url: "http://your-grocery-api/remove_from_grocery_list"
    method: POST
    content_type: application/json
    payload: '{"items": ["{{ item }}"]}'
```

If you don't have that backend, the swipe will animate the row off-screen but the underlying inventory won't change.

## 7. (Optional) Sidebar dashboard

If you want the page to appear in HA's sidebar in addition to being served at `/local/jarvis/index.html`, register it as a YAML dashboard. See [`setup/dashboard.yaml`](../setup/dashboard.yaml).
