import CodeBlock                 from '$lib/components/code-block/+component.svelte'
import Fa                        from 'svelte-fa/src/fa.svelte'
import { faTriangleExclamation } from '@fortawesome/free-solid-svg-icons'
import { Toaster }               from 'svelte-french-toast'

code =
  start:
    install:
      yarn:
        text: """
          λ yarn add flame-odm
          """
        copy: """
          yarn add flame-odm
          """
    connect:
      coffee:
        text: """
          Adapter = require 'flame-odm/adapter'

          service_account = {
            type: "service_account"
            project_id: "..."
            # ...
          }

          adapter = new Adapter(service_account)
        """
    define_model:
      coffee:
        text: """
          # (cont.)

          Model   = require 'flame-odm/model'
          rand    = require '@stablelib/random'

          User = new Model('User', {
            id:    -> 'user-' + rand.randomString(32)
            name:  null
            email: null
          }, adapter)
        """
    create_record:
      coffee:
        text: """
          # (cont.)

          record = User.create({
            name: 'Dragon'
          })

          console.log(record.obj())
          # => {
          #   id: 'user-KXKstn9KZZqhuW9MKJFEb7qggEVbeVFR'
          #   name: 'Dragon'
          #   email: null
          # }
        """
    save_record:
      coffee:
        text: """
          # (cont.)
          saved = await record.save()
          console.log(saved)
          # => true
        """
    run_query:
      coffee:
        text: """
          # (cont.)
          Query = require 'flame-odm/query'

          userQ = new Query([
            [ 'eq', 'name', 'Dragon' ]
          ])

          user = await User.find(userQ)
          console.log user
          # => {
          #   id: 'user-KXKstn9KZZqhuW9MKJFEb7qggEVbeVFR'
          #   name: 'Dragon'
          #   email: null
          # }
        """
  api:
    access:
      'new':
        code: """
          Access = require 'flame-odm/access'

          access = new Access({
            name: [ 'user', 'self' ]
            age:  [ 'self' ]
          })
        """
      screen:
        code: """
          Access = require 'flame-odm/access'

          access = new Access({
            name: [ 'user', 'self' ]
            age:  [ 'self' ]
          })

          screened = access.screen({ name: 'Emma', age: 28 }, [ 'user' ])
          # => { name: 'Emma' }

        """
      fields:
        code: """
          Access = require 'flame-odm/access'

          access = new Access({
            name: [ 'user', 'self' ]
            age:  [ 'self' ]
          })

          fields = access.fields([ 'self' ])
          # => [ 'name', 'age' ]

        """
    adapter:
      'new':
        coffee:
          text: """
            Adapter = require 'flame-odm/adapter'

            service_account = {
              type: "service_account"
              project_id: "..."
              # ...
            }

            adapter = new Adapter(service_account)
          """
      connect:
        code: """
          Adapter = require 'flame-odm/adapter'

          service_account = {
            type: "service_account"
            project_id: "..."
            # ...
          }

          adapter = new Adapter(service_account)

          await adapter.connect()
        """
      transact:
        code: """
          Adapter  = require 'flame-odm/adapter'
          Alphabet = require '◆/lib/flame/models/alphabet.coffee'
          Query    = require 'flame-odm/query'

          alphabet_query = new Query([
            [ 'eq', 'letter', 'a' ]
          ])

          ok = await Adapter.transact((T) ->
            letter_a = await Alphabet.find(alphabet_query, T)

            if !letter_a
              letter_a2 = Alphabet.create({ letter: 'a' })
              saved = await letter_a2.save(T)

            return (!!letter_a || saved)
          )

          console.log(ok)
          # => true
          """
    config:
      'new':
        coffee:
          text: """
            Config = require 'flame-odm/config'
            Model  = require 'flame-odm/model'
            rand   = require '@stablelib/random'

            config = new Config({
              id_field: 'id'
            })

            User = new Model('User', {
              id: -> 'user-' + rand.randomString(32)
            }, config)
            # The id field of each User model will now be used as its Document ID Firestore.
          """
    model:
      'new':
        coffee:
          text: """
            Model = require 'flame-odm/model'

            User = new Model('User', {
              id:   null
              name: null
            })
          """
      count:
        coffee:
          text: """
            map   = require 'lodash/map'
            split = require 'lodash/split'

            Model = require 'flame-odm/model'
            Query = require 'flame-odm/query'

            Alphabet = new Model('Alphabet', {
              letter: null
            })

            letters = split('abcdefghijklmnopqrstuvwxyz')
            await all(map(letters, (letter) -> Alphabet.create({ letter }).save()))

            query = new Query([
              [ 'gt',  'letter', 'b' ]
              [ 'lte', 'letter', 'f' ]
            ])

            cdef = await Alphabet.count(query)
            # => 4
          """
      create:
        coffee:
          text: """
            Model = require 'flame-odm/model'

            Alphabet = new Model('Alphabet', {
              letter: null
            })

            record = Alphabet.create({ letter: 'a' })
            # => (Record)
          """
      del:
        coffee:
          text: """
            map   = require 'lodash/map'
            split = require 'lodash/split'

            Config = require 'flame-odm/config'
            Model  = require 'flame-odm/model'

            C = new Config({
              id_field:         'letter'
              deleted_field:    'deleted'
              deleted_at_field: 'deleted_at'
              updated_at_field: 'updated_at'
            })

            Alphabet = new Model('Alphabet', {
              letter:     null
              deleted:    -> false
              deleted_at: -> null
              updated_at: -> new Date().toISOString()
            }, C)

            letters = split('abcdefghijklmnopqrstuvwxyz')
            await all(map(letters, (letter) -> Alphabet.create({ letter }).save()))

            ok = await Alphabet.del('a')
            # => true
            # The 'a' document is now { letter: 'a', deleted: true, deleted_at: <timestamp>, updated_at: <unchanged> }
          """
      extend:
        coffee:
          text: """
            Model = require 'flame-odm/model'

            Vehicle = new Model('Vehicle', {
              weight: null
            })

            Car = Vehicle.extend('Car', {
              wheels: 4
            })
          """
      find:
        coffee:
          text: """
            map   = require 'lodash/map'
            split = require 'lodash/split'

            Model = require 'flame-odm/model'
            Query = require 'flame-odm/query'

            Alphabet = new Model('Alphabet', {
              letter: null
            })

            letters = split('abcdefghijklmnopqrstuvwxyz')
            await all(map(letters, (letter) -> Alphabet.create({ letter }).save()))

            query = new Query([
              [ 'gt',  'letter', 'b' ]
            ])

            c = await Alphabet.find(query)
            # => { letter: 'c' }
          """
      find_all:
        coffee:
          text: """
            map   = require 'lodash/map'
            split = require 'lodash/split'

            Model = require 'flame-odm/model'
            Query = require 'flame-odm/query'

            Alphabet = new Model('Alphabet', {
              letter: null
            })

            letters = split('abcdefghijklmnopqrstuvwxyz')
            await all(map(letters, (letter) -> Alphabet.create({ letter }).save()))

            query = new Query([
              [ 'eq-any', 'letter', [ 'a', 'e', 'i', 'o', 'u', 'y' ]]
            ])

            vowels = await Alphabet.findAll(query)
            # => [{ letter: 'a' }, { letter: 'e' }, { letter: 'i' }, { letter: 'o' }, { letter: 'u' }, { letter: 'y' }]
          """
      fragment:
        coffee:
          text: """
            Model = require 'flame-odm/model'
            rand  = require '@stablelib/random'

            User = new Model('User', {
              id:   -> 'user-' + rand.randomString(4)
              name: null
              bday: null
            })

            record = User.create({
              name: 'Ella'
            })
            await record.save()

            record_v2 = User.fragment(record.obj().id, {
              bday: '2020-02-02'
            })
            await record_v2.update([ 'bday' ])
            # => true
          """
      get:
        coffee:
          text: """
            map   = require 'lodash/map'
            split = require 'lodash/split'

            Config = require 'flame-odm/config'
            Model  = require 'flame-odm/model'
            Query  = require 'flame-odm/query'

            C = new Config({
              id_field: 'letter'
            })

            Alphabet = new Model('Alphabet', {
              letter: null
            }, C)

            letters = split('abcdefghijklmnopqrstuvwxyz')
            await all(map(letters, (letter) -> Alphabet.create({ letter }).save()))

            a = await Alphabet.get('a')
            # => { letter: 'a' }
          """
      get_all:
        coffee:
          text: """
            map   = require 'lodash/map'
            split = require 'lodash/split'

            Config = require 'flame-odm/config'
            Model  = require 'flame-odm/model'
            Query  = require 'flame-odm/query'

            C = new Config({
              id_field: 'letter'
            })

            Alphabet = new Model('Alphabet', {
              letter: null
            }, C)

            letters = split('abcdefghijklmnopqrstuvwxyz')
            await all(map(letters, (letter) -> Alphabet.create({ letter }).save()))

            a = await Alphabet.getAll([ 'a', 'zz', 'z' ])
            # => [{ letter: 'a' }, null, { letter: 'z' }]
          """
      page:
        coffee:
          text: """
            map   = require 'lodash/map'
            split = require 'lodash/split'

            Config = require 'flame-odm/config'
            Model  = require 'flame-odm/model'
            Pager  = require 'flame-odm/pager'

            Alphabet = new Model('Alphabet', {
              letter: null
            })

            letters = split('abcdefghijklmnopqrstuvwxyz')
            await all(map(letters, (letter) -> Alphabet.create({ letter }).save()))

            pager = (new Pager [
              [ 'order-by', 'letter', 'asc' ]
            ], { size: 4 })

            cursor = {
              obj: { letter: 'd' }
              position: 'page-start'
            }

            page = await Alphabet.page(pager, cursor)
            # => {
            #   counts: { total: 26, before: 3, page: 4, after: 19 },
            #   collection: {
            #     first: { letter: 'a', },
            #     last: { letter: 'z', }
            #   },
            #   page: {
            #     first: { letter: 'd'},
            #     items: [
            #       { letter: 'd', },
            #       { letter: 'e', },
            #       { letter: 'f', },
            #       { letter: 'g', }
            #     ],
            #     last: { letter: 'g', }
            #   },
            #   cursors: {
            #     previous: {
            #       obj: { letter: 'c', },
            #       position: 'page-end'
            #     },
            #     current: {
            #       obj: { letter: 'd' },
            #       position: 'page-start'
            #     },
            #     next: {
            #       obj: { letter: 'h' },
            #       position: 'page-start'
            #     }
            #   }
            # }
          """
      traverse:
        coffee:
          text: """
            map    = require 'lodash/map'
            repeat = require 'lodash/repeat'
            split  = require 'lodash/split'

            Config = require 'flame-odm/config'
            Model  = require 'flame-odm/model'
            Pager  = require 'flame-odm/pager'

            Alphabet = new Model('Alphabet', {
              letter: null
            })

            letters = split('abcdefghijklmnopqrstuvwxyz')
            await all(map(letters, (letter) -> Alphabet.create({ letter }).save()))

            pager = (new Pager [
              [ 'order-by', 'letter', 'asc' ]
            ], { size: 6 })

            await Alphabet.traverse(pager, ((record) ->
              await Alphabet.create({ letter: repeat(record.letter, 2) }).save()
              return
            ))
            # The 'alphabet' collection will now have records with with { letter: 'a' }, { letter: 'aa' }, { letter: 'b' }, { letter: 'bb' }, ...
          """
    pager:
      'new':
        coffee:
          text: """
            Pager  = require 'flame-odm/pager'

            pager = new Pager([
              [ 'gt',       'letter', 'f' ]
              [ 'order-by', 'letter', 'asc' ]
            ], { size: 6 })
          """
    query:
      'new':
        coffee:
          text: """
            Query  = require 'flame-odm/query'

            query = new Query([
              [ 'gte',    'letter', 'm' ]
              [ 'eq-any', 'letter', [ 'a', 'e', 'i', 'o', 'u', 'y', ]]
            ])
          """
    record:
      destroy:
        coffee:
          text: """
            map    = require 'lodash/map'
            split  = require 'lodash/split'

            Config = require 'flame-odm/config'
            Model  = require 'flame-odm/model'

            config = new Config({
              id_field: 'letter'
            })

            Alphabet = new Model('Alphabet', {
              letter: null
            }, config)

            letters = split('abcdefghijklmnopqrstuvwxyz')
            await all(map(letters, (letter) -> Alphabet.create({ letter }).save()))

            record = Alphabet.fragment('a')
            await record.destroy()
            # => true
          """
      errors:
        coffee:
          text: """
            Model     = require 'flame-odm/model'
            Validator = require 'flame-odm/validator'

            validator = new Validator({
              letter: (value, object) -> /^[a-z]+$/.test(value)
            })

            Alphabet = new Model('Alphabet', {
              letter: null
            }, validator)

            record = Alphabet.create({ letter: 10 })
            errors = record.errors()
            # => { letter: true }
          """
      obj:
        coffee:
          text: """
            Model = require 'flame-odm/model'

            Alphabet = new Model('Alphabet', {
              letter: null
            })

            record = Alphabet.create({ letter: 'z' })
            record.obj()
            # => { letter: 'z' }
          """
      ok:
        coffee:
          text: """
            Model     = require 'flame-odm/model'
            Validator = require 'flame-odm/validator'

            validator = new Validator({
              letter: (value, object) -> /^[a-z]+$/.test(value)
            })

            Alphabet = new Model('Alphabet', {
              letter: null
            }, validator)

            record = Alphabet.create({ letter: 10 })
            ok = record.ok()
            # => false
          """
      save:
        coffee:
          text: """
            Model = require 'flame-odm/model'

            Alphabet = new Model('Alphabet', {
              letter: null
            })

            record = Alphabet.create({ letter: 'm' })
            await record.save()
            # => true
          """
      update:
        coffee:
          text: """
            Model = require 'flame-odm/model'
            rand  = require '@stablelib/random'

            User = new Model('User', {
              id:   -> 'user-' + rand.randomString(4)
              name: null
              bday: null
            })

            record = User.create({
              name: 'Billy'
            })
            await record.save()

            record_v2 = User.fragment(record.obj().id, {
              bday: '2011-11-02'
            })
            await record_v2.update([ 'bday' ])
            # => true
          """
    serializer:
      'new':
        coffee:
          text: """
            Serializer = require 'flame-odm/serializer'

            serializer = new Serializer({
              prefixes: [ 'ext', 'index', 'meta', 'rel', 'val' ]
              separator: '-'
              fmt: {
                db:  { field: 'kebab' }
                obj: { field: 'snake' }
              }
            })
          """
    validator:
      'new':
        coffee:
          text: """
            Model     = require 'flame-odm/model'
            Validator = require 'flame-odm/validator'

            validator = new Validator({
              letter: (value, object) -> /^[a-z]+$/.test(value)
            })

            Alphabet = new Model('Alphabet', {
              letter: null
            }, validator)
          """
