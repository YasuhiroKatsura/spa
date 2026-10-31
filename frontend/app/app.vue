<template>
  <main class="page">
    <NuxtRouteAnnouncer />
    <header class="topbar">
      <a class="brand" href="/">Sample SPA</a>
      <span class="sample-badge">SAMPLE APP</span>
    </header>

    <section class="hero">
      <p class="eyebrow">NUXT + VUE</p>
      <h1>サンプルアプリへようこそ</h1>
      <p class="intro">
        フロントエンドの表示を確認するためのサンプル画面です。
      </p>
    </section>

    <section class="api-card" aria-labelledby="api-heading">
      <div class="card-heading">
        <div>
          <p class="eyebrow">BACKEND CONNECTION</p>
          <h2 id="api-heading">APIレスポンス</h2>
        </div>
        <span class="status">未接続</span>
      </div>
      <p class="message">バックエンドAPIはまだありません。現在はAPIへの接続を行っていません。</p>
    </section>

    <footer>Sample SPA · Built with Nuxt</footer>
  </main>
</template>

<style scoped>
.page {
  box-sizing: border-box;
  min-height: 100vh;
  padding: 0 1.5rem;
  background: #f5f7fb;
  color: #172033;
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  max-width: 960px;
  height: 76px;
  margin: 0 auto;
  border-bottom: 1px solid #e3e8f1;
}

.brand {
  color: #172033;
  font-size: 1.1rem;
  font-weight: 750;
  text-decoration: none;
}

.sample-badge,
.status {
  border-radius: 999px;
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.06em;
}

.sample-badge {
  padding: 0.45rem 0.7rem;
  background: #e8efff;
  color: #3158b8;
}

.hero,
.api-card {
  max-width: 760px;
  margin-right: auto;
  margin-left: auto;
}

.hero {
  padding: 5rem 0 2.5rem;
}

.eyebrow {
  margin: 0 0 0.75rem;
  color: #5272c4;
  font-size: 0.75rem;
  font-weight: 750;
  letter-spacing: 0.12em;
}

h1 {
  margin: 0;
  font-size: clamp(2rem, 5vw, 3.25rem);
  letter-spacing: -0.045em;
  line-height: 1.2;
}

.intro {
  max-width: 36rem;
  margin: 1rem 0 0;
  color: #64708a;
  font-size: 1.05rem;
  line-height: 1.7;
}

.api-card {
  box-sizing: border-box;
  padding: 1.75rem;
  border: 1px solid #e5eaf2;
  border-radius: 16px;
  background: #fff;
  box-shadow: 0 12px 35px rgb(34 53 89 / 6%);
}

.card-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

h2 {
  margin: 0;
  font-size: 1.25rem;
}

.status {
  padding: 0.45rem 0.7rem;
  background: #e9f7ef;
  color: #247449;
  white-space: nowrap;
}

.message {
  margin: 1.5rem 0 0;
  color: #64708a;
}

footer {
  max-width: 760px;
  margin: 2rem auto 0;
  padding-bottom: 2rem;
  color: #8993a8;
  font-size: 0.85rem;
}

@media (max-width: 600px) {
  .page {
    padding: 0 1rem;
  }

  .hero {
    padding-top: 3.5rem;
  }

  .api-card {
    padding: 1.25rem;
  }
}
</style>
