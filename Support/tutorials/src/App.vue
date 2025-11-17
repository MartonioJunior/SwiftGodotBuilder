<template>
  <div id="app">
    <router-view />
  </div>
</template>

<script>
export default {
  name: 'App'
};
</script>

<style>
html,
body {
  margin: 0;
  padding: 0;
  line-height: 1.3;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, "Open Sans", "Helvetica Neue", sans-serif;
}

main.vue-tut {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, "Open Sans", "Helvetica Neue", sans-serif;
  line-height: 1.3;
}

main.vue-tut pre {
  font-family: SFMono, Consolas, "Liberation Mono", Monaco, Menlo, Courier, monospace;
}

main.vue-tut code {
  font-family: SFMono, Consolas, "Liberation Mono", Monaco, Menlo, Courier, monospace;
  background-color: #ececec;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 0.9em;
}

main.vue-tut hr {
  margin: 1.5em 0;
  border: none;
  border-top: 1px solid #e0e0e0;
}

main.vue-tut * {
  letter-spacing: initial !important;
}

main.vue-tut ul {
  padding-left: 1em;
}

main.vue-tut li {
  margin-bottom: 0.5em;
}

main.vue-tut p {
  line-height: 1.3;
}
</style>
