import Vue from 'vue';
import VueRouter from 'vue-router';
import Home from '../views/Home.vue';
import Chapter1 from '../views/Chapter1.vue';
import Chapter2 from '../views/Chapter2.vue';
import Chapter3 from '../views/Chapter3.vue';
import Chapter4 from '../views/Chapter4.vue';
import Chapter5 from '../views/Chapter5.vue';

Vue.use(VueRouter);

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/swift-runner/chapter-1',
    name: 'Chapter1',
    component: Chapter1
  },
  {
    path: '/swift-runner/chapter-2',
    name: 'Chapter2',
    component: Chapter2
  },
  {
    path: '/swift-runner/chapter-3',
    name: 'Chapter3',
    component: Chapter3
  },
  {
    path: '/swift-runner/chapter-4',
    name: 'Chapter4',
    component: Chapter4
  },
  {
    path: '/swift-runner/chapter-5',
    name: 'Chapter5',
    component: Chapter5
  }
];

const router = new VueRouter({
  mode: 'history',
  routes
});

export default router;
