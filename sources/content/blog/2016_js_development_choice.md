+++
author = "Zip Random"
tags = ["javascript", "react", "functional"]
title = "2016 - Personal Choice for WebApp Development"
date = "2016-09-23T16:00:00-03:00"
draft = false
+++

Just a snapshot of what I use for effective & fun JS Webdevelopment right now.

<!--more-->

Js Webapp development has become really fun for me since I discovered [React](https://facebook.github.io/react/). What I do ever since is build UI centric Applications around a preferably immutable state. I tried [Redux](http://redux.js.org/) but found it to be overhead for the small applications I developed. So I mostly stick with [Baobab](https://github.com/Yomguithereal/baobab) that I serve as a [RxJS](https://github.com/Reactive-Extensions/RxJS) [Observable Sequence](https://github.com/Reactive-Extensions/RxJS/blob/master/doc/gettingstarted/creating.md), a Stream that floats through the Application from (abstraction) top to bottom.

### UI / Templating: React (Stateless) Functional Components

**Template Component**
```javascript
const PostsTemplate = ({posts, page, setPage}) => (
  <div>
    /* Navigation */
    {posts.map(
      (_, index) => (
        <a onClick={() => setPage(index)}>
          {index}
        </a>
      )
    )}
    /* Posts Carousel */
    <Slider>
    {posts.map(
      (post, index) => (
        <Slide className={index == page ? 'active' : 'hidden'}>
          <PostTemplate post={post} />
        </Slide>
      )
    )}
    </Slider>
  </div>
);
```

**Higher Order Component to Decorate Template with State Stream derived Data**
```javascript
const OnPostsFromStateRefresh = recompose.compose(
  recompose.mapPropsStream(
    () => stateStream.distinctUntilChanged(
      /* wait until (posts or page) change
         ignore rest of the states updates */
      (state) => [
          state.get('posts'), state.get('page')
      ]
    )
  ),
  /* extract what we need to render the
     PostsTemplate */
  recompose.mapProps(
    (state) => ({
      posts: state.get('posts'),
      page: state.get('page'),
      /* here we take a cursor
         and pass its set function */
      setPage: state.select('page').set
    })
  )
);
```

**Combine Template and Higher Order Component**
```javascript
module.exports = OnPostsFromStateRefresh(PostsTemplate);
```

I create hierarchical React components to layout the UI. React can express all of the UI's logic and depends on the state for the data to display. The state or relevant-sections of it as [cursors](https://github.com/Yomguithereal/baobab#cursors) get passed down the component hierarchy from the abstract ```<App>...</App``` component down to the ```<button onClick={..}>...</button>``` that directly renders to the button dom element. I don't use ES6 Classes to express components, but define components as Pure Functions that take properties (including state) and return Virtual Dom Nodes. By Nesting Pure Functional Components in HoC a separation of logic is achieved in a functional way, not unlike Rails` middleware onion. I make excessive use of the Higher Order Components provided by the [React utility belt Recompose](https://github.com/acdlite/recompose/blob/master/docs/API.md) that also help in coupling Dom to the states Observable Stream.

### Processing / Building / Bundling

The by far handiest js build system and dev server I've encoutered is [Webpack](https://webpack.github.io/). I use it with the [Babel](https://babeljs.io/docs/setup/#installation) transpiler to polyfill ES6 Syntax (```({a, b}) => ({a,...b})```) with Reacts JSX ```<MyFunkyComponent/>``` as well as preprocess and deliver (s)css, fonts and assets bundled inside that same minified js file. Basically everything is available through the ```import``` (```@import``` for styles) or ```require``` syntax. I love it so much! [Node Package Manager](https://www.npmjs.com/) is used to install everything I need. And [docker](https://www.docker.com/) Hosts the whole js dev environment.

### Immutable Global State
```javascript
import BaoBab form 'baobab';
import recompose from 'recompose';

// the initial State
let state = new BaoBab({
    posts: [],
    page: 0
});

// couple the BaoBab event based updateCallback
// with an Observable Stream
let handler = recompose.createEventHandler(state);
state.on('update',
  event => handler.handler(event.target)
)

// create a higher order component
// to wrap react components with
// stateStream updates
let onStateStream = recompose.mapPropsStream(
  props$ => handler.stream.startWith(state)
);

module.exports(onStateStream)
```

The state basically is **one big immutable Hash that gets passed to the Component (Render) Functions whenever it updates**. The keys that didn't change still have the same id. So for an unchanged key ```a```

```javascript
oldState.get('a')
  === newState.get('a')
```

holds and components that are guarded by the ```recompose.pure()``` Higher Order Component don't do unnecessary updates. If the value of a part of the tree change you are garanteed to get a new Object ```!==``` the old State

```javascript
postsCursor =
  state.select('posts')
```

returns a cursor that can be used to retrieve the value ```postsCursor.get()``` as well as trigger a state update ```postsCursor.set([])```. Parts of the State can also be subscribed.

```javasrcript
postsCursor.on(
  'update',
  (posts) => ...
)
```

### IDE / Editing

Emacs, what else :D [web-mode](http://web-mode.org/) does a nice job highlighting and aligning es6 syntax and various template languages like JSX. Also did I find [magit](https://magit.vc/) to be the best way to use git.

### Libs/Services

The Ajax Library of choice is [superagent](http://visionmedia.github.io/superagent/).

### Testing

I use [chimp](https://chimp.readme.io/) to run end-to-end tests defined in [cucumber scenarios](https://chimp.readme.io/docs/getting-started). The nice separation of concerns let's us easily test the dom independent parts like state and services with [yasmine unit tests](http://jasmine.github.io/).

For single page apps I like to write ```DomInteraction-to-ApiCall``` & ```ApiResults-to-DomLayout``` e2e-tests. Therefore I created a set of cucumber steps to define backend API mocks and ajax expectation inline in the gherkin file. From [github/cucumberjs-json-api-mocking](https://github.com/ziprandom/cucumberjs-json-api-mocking):

```gherkin
# The XMLHttpRequest and Response Mocks are
# injected into the browser context. Every
# call now gets intercepted,logged and answered
# if a proper response is defined.
And I start mocking "http://localhost:8000"

# An API request is triggered via the ui
When I input "My fancy new Todo" into the Todo Input
And I press Return

# Expected API behavior can be defined after the request
Then a "post" to "/api/todos" should have happened with:
"""
  {
    "title": "My fancy new Todo",
    "completed": false
  }
"""

# API mocks can also be defined after the request was made
# a loop waits 5 secs before a timeout is triggered.
Given the API responds to the "post" on "/api/todos" with "201":
"""
  {
    "id": 5701886678138880,
    "title": "My fancy new Todo",
    "completed": false
  }
"""

# When we made sure, the app makes the right api calls
# and provide it with backend feedback we can go on
# testing the ui.
Then an active Todo "My fancy new Todo" should be visible
```
