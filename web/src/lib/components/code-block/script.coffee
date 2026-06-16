import "svelte-highlight/styles/stackoverflow-dark.css"
import coffeescript    from "svelte-highlight/languages/coffeescript"
import Fa              from 'svelte-fa/src/fa.svelte'
import Highlight       from "svelte-highlight"
import javascript      from "svelte-highlight/languages/javascript"
import shell           from "svelte-highlight/languages/shell"
import toast           from 'svelte-french-toast'
import { copy }        from 'svelte-copy'
import { faCopy }      from '@fortawesome/free-solid-svg-icons'
import { faFile }      from '@fortawesome/free-solid-svg-icons'
import { faFolder }    from '@fortawesome/free-solid-svg-icons'
import { faTerminal }  from '@fortawesome/free-solid-svg-icons'
import { LineNumbers } from "svelte-highlight"
import { Toaster }     from 'svelte-french-toast'

`export let cp`
`export let fd`
`export let ui`

copyToast = ->
  (toast 'Copied', {
    duration: 1200
    position: 'bottom-center'
    style:    'background: #333; color: #fff; padding: 2px 4px; border-radius: 8px;'
  })

