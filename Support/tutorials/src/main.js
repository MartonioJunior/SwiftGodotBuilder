import Vue from "vue";
import App from "./App.vue";
import router from "./router";
import VueTut from 'vue-tut';
import 'vue-tut/dist/vue-tut.min.css';
import 'vue-tut/dist/themes/azure.css';
import 'vue-tut/dist/code-themes/darcula.css';

Vue.use(VueTut);

Vue.config.productionTip = false;

new Vue({
  router,
  render: h => h(App)
}).$mount("#app");
