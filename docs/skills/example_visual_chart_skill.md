# Example Visual Chart Skill

Use this pattern inside a skill's `instructions` field so the model emits only structured payload JSON.

## Output Contract

Return exactly one JSON object with this schema and no extra prose:

```json
{
  "type": "html_app",
  "html": "<body content only, no <html>/<head>/<body> wrappers>",
  "css": "plain CSS string",
  "js": "plain JavaScript string",
  "assets": {},
  "actions": []
}
```

Rules:
- Never include wrapper tags (`<html>`, `<head>`, `<body>`).
- Never include markdown fences.
- Never reference external CDN URLs unless declared in `assets`.

## Example Prompt Snippet

```
You are generating visual output for a Flutter renderer.
Return only a JSON object matching the html_app schema.
Build a simple bar chart for lesson demand by day using only vanilla JS/CSS.
Include one action declaration:
{
  "name": "emitEvent",
  "payload": { "event": "bar_click", "day": "<day>" }
}
```

## Example Valid Payload

```json
{
  "type": "html_app",
  "html": "<h2>Weekly Lesson Demand</h2><div id=\"bars\"></div>",
  "css": "#bars{display:flex;gap:10px;align-items:flex-end;height:180px}.bar{width:36px;background:#4e71ff;border-radius:8px 8px 0 0;cursor:pointer}.label{font-size:12px;color:#9eb1da;text-align:center;margin-top:6px}",
  "js": "const data=[['Mon',4],['Tue',7],['Wed',5],['Thu',8],['Fri',6]];const root=document.getElementById('bars');data.forEach(([day,val])=>{const wrap=document.createElement('div');const bar=document.createElement('div');bar.className='bar';bar.style.height=`${val*18}px`;bar.title=`${day}: ${val}`;bar.addEventListener('click',()=>window.ParavioBridge?.postAction('emitEvent',{event:'bar_click',day,value:val}));const label=document.createElement('div');label.className='label';label.textContent=day;wrap.appendChild(bar);wrap.appendChild(label);root.appendChild(wrap);});",
  "assets": {},
  "actions": [
    {
      "name": "emitEvent",
      "payload": {
        "event": "bar_click",
        "day": "string"
      }
    }
  ]
}
```
