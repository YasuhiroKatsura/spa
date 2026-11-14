<script setup lang="ts">
import {
  InteractionRequiredAuthError,
  PublicClientApplication,
  type AccountInfo
} from '@azure/msal-browser'

const config = useRuntimeConfig()
const tenantId = config.public.entraTenantId
const clientId = config.public.entraClientId
const apiScope = config.public.entraApiScope
const apiBaseUrl = config.public.apiBaseUrl

const account = ref<AccountInfo | null>(null)
const status = ref('認証設定を確認しています')
const errorMessage = ref('')
const apiResponse = ref('')
const isReady = ref(false)
const isRequesting = ref(false)

let msalApp: PublicClientApplication | undefined

onMounted(async () => {
  try {
    if (!tenantId || !clientId || !apiScope || !apiBaseUrl) {
      throw new Error('フロントエンドの認証設定が不足しています。.envを確認してください。')
    }

    msalApp = new PublicClientApplication({
      auth: {
        clientId,
        authority: `https://login.microsoftonline.com/${tenantId}`,
        redirectUri: window.location.origin
      },
      cache: {
        cacheLocation: 'sessionStorage'
      }
    })

    await msalApp.initialize()
    const redirectResult = await msalApp.handleRedirectPromise()
    const signedInAccount = redirectResult?.account ?? msalApp.getActiveAccount() ?? msalApp.getAllAccounts()[0] ?? null
    if (signedInAccount) {
      msalApp.setActiveAccount(signedInAccount)
    }

    account.value = signedInAccount
    status.value = signedInAccount ? '認証済み' : '未認証'
    isReady.value = true
  } catch (error) {
    status.value = '認証設定エラー'
    errorMessage.value = error instanceof Error ? error.message : '認証の初期化に失敗しました。'
  }
})

async function signIn() {
  if (!msalApp) return

  errorMessage.value = ''
  try {
    await msalApp.loginRedirect({ scopes: [apiScope] })
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : 'サインインを開始できませんでした。'
  }
}

async function signOut() {
  if (!msalApp || !account.value) return

  errorMessage.value = ''
  try {
    await msalApp.logoutRedirect({
      account: account.value,
      postLogoutRedirectUri: window.location.origin
    })
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : 'サインアウトできませんでした。'
  }
}

async function callApi() {
  if (!msalApp || !account.value) return

  isRequesting.value = true
  errorMessage.value = ''
  apiResponse.value = ''
  try {
    let accessToken: string
    try {
      const tokenResult = await msalApp.acquireTokenSilent({
        scopes: [apiScope],
        account: account.value
      })
      accessToken = tokenResult.accessToken
    } catch (error) {
      if (!(error instanceof InteractionRequiredAuthError)) {
        throw error
      }

      await msalApp.acquireTokenRedirect({
        scopes: [apiScope],
        account: account.value
      })
      return
    }

    const response = await fetch(apiBaseUrl, {
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    })
    const responseText = await response.text()
    if (!response.ok) {
      throw new Error(`APIからHTTP ${response.status}が返されました: ${responseText}`)
    }

    apiResponse.value = responseText || `HTTP ${response.status}`
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : 'APIの呼び出しに失敗しました。'
  } finally {
    isRequesting.value = false
  }
}
</script>

<template>
  <main class="page">
    <NuxtRouteAnnouncer />
    <header class="topbar">
      <a class="brand" href="/">Sample SPA</a>
      <span class="sample-badge">SAMPLE APP</span>
    </header>

    <section class="hero">
      <p class="eyebrow">NUXT + MICROSOFT ENTRA ID</p>
      <h1>サンプルアプリへようこそ</h1>
      <p class="intro">
        フロントエンドの表示を確認するためのサンプル画面です。
      </p>
    </section>

    <section class="api-card" aria-labelledby="api-heading">
      <div class="card-heading">
        <div>
          <p class="eyebrow">API GATEWAY JWT AUTHORIZER</p>
          <h2 id="api-heading">認証とAPI接続</h2>
        </div>
        <span class="status" :class="{ 'status-authenticated': account }" aria-live="polite">
          {{ status }}
        </span>
      </div>

      <p v-if="account" class="message">サインイン中: {{ account.username }}</p>
      <p v-else class="message">サインインすると、API用のアクセストークンを取得できます。</p>

      <div class="actions">
        <button v-if="!account" type="button" :disabled="!isReady" @click="signIn">
          Microsoftでサインイン
        </button>
        <template v-else>
          <button type="button" :disabled="isRequesting" @click="callApi">
            {{ isRequesting ? 'API呼び出し中...' : '認証付きでAPIを呼び出す' }}
          </button>
          <button class="secondary" type="button" @click="signOut">サインアウト</button>
        </template>
      </div>

      <pre v-if="apiResponse" class="api-response" aria-live="polite">{{ apiResponse }}</pre>
      <p v-if="errorMessage" class="error" role="alert">{{ errorMessage }}</p>
    </section>

    <footer>Sample SPA · Built with Nuxt and MSAL</footer>
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
  background: #fff5df;
  color: #88640f;
  white-space: nowrap;
}

.status-authenticated {
  background: #e9f7ef;
  color: #247449;
}

.message {
  margin: 1.5rem 0 0;
  color: #64708a;
}

.actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-top: 1.25rem;
}

button {
  padding: 0.7rem 1rem;
  border: 0;
  border-radius: 8px;
  background: #3158b8;
  color: white;
  cursor: pointer;
  font: inherit;
  font-weight: 650;
}

button:disabled {
  cursor: wait;
  opacity: 0.6;
}

button.secondary {
  border: 1px solid #d5dceb;
  background: white;
  color: #3158b8;
}

.api-response {
  overflow: auto;
  margin: 1.25rem 0 0;
  padding: 1rem;
  border-radius: 8px;
  background: #f5f7fb;
  color: #172033;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}

.error {
  margin: 1rem 0 0;
  color: #b42318;
  overflow-wrap: anywhere;
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
