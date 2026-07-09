extends RefCounted

const REQUEST_TIMEOUT_SEC := 8.0

const BRIDGE_BOOTSTRAP := """
(function () {
  if (window.__godotMiniGameBridge) {
    return "already_ready";
  }

  function safeStringify(value) {
    try {
      return JSON.stringify(value);
    } catch (error) {
      return JSON.stringify({
        ok: false,
        reason: "json_stringify_failed",
        message: String(error && error.message ? error.message : error)
      });
    }
  }

  function parseJson(input) {
    if (!input) return {};
    if (typeof input === "object") return input;
    try {
      return JSON.parse(input);
    } catch (_error) {
      return {};
    }
  }

  function createResult(ok, extra) {
    const base = { ok: ok };
    if (extra && typeof extra === "object") {
      Object.keys(extra).forEach((key) => {
        base[key] = extra[key];
      });
    }
    return base;
  }

  const bridge = {
    config: {},
    pendingResults: {},
    requestSeed: 1,
    rewardedAds: {},
    lifecycleBound: false,
    state: {
      visible: true,
      lastShowOptions: {},
      lastHideAt: 0,
      lastShowAt: Date.now()
    },

    detectPlatform: function () {
      if (typeof wx !== "undefined" && wx && typeof wx.login === "function") {
        return "wechat";
      }
      if (typeof tt !== "undefined" && tt && typeof tt.login === "function") {
        return "douyin";
      }
      return "browser";
    },

    getApi: function () {
      const platform = this.detectPlatform();
      if (platform === "wechat") return wx;
      if (platform === "douyin") return tt;
      return null;
    },

    getPlatformConfig: function () {
      const runtime = this.detectPlatform();
      return this.config[runtime] || {};
    },

    configure: function (configJson) {
      this.config = parseJson(configJson);
      this.bindLifecycle();
      this.ensureShareMenu();
      return safeStringify(createResult(true, {
        platform: this.detectPlatform(),
        configLoaded: true
      }));
    },

    bindLifecycle: function () {
      if (this.lifecycleBound) {
        return;
      }
      const api = this.getApi();
      if (!api) {
        return;
      }
      if (typeof api.onShow === "function") {
        api.onShow((options) => {
          this.state.visible = true;
          this.state.lastShowAt = Date.now();
          this.state.lastShowOptions = options || {};
        });
      }
      if (typeof api.onHide === "function") {
        api.onHide(() => {
          this.state.visible = false;
          this.state.lastHideAt = Date.now();
        });
      }
      this.lifecycleBound = true;
    },

    ensureShareMenu: function () {
      const api = this.getApi();
      const platform = this.detectPlatform();
      const cfg = this.getPlatformConfig();

      if (!api) {
        return createResult(false, {
          reason: "platform_api_missing",
          message: "未检测到小游戏平台 API"
        });
      }

      try {
        if (platform === "wechat" && typeof api.showShareMenu === "function") {
          const menus = ["shareAppMessage"];
          if (cfg.enable_share_timeline) {
            menus.push("shareTimeline");
          }
          api.showShareMenu({
            withShareTicket: true,
            menus: menus
          });
          return createResult(true, {
            platform: platform,
            menus: menus
          });
        }

        if (platform === "douyin" && typeof api.showShareMenu === "function") {
          api.showShareMenu({});
          return createResult(true, {
            platform: platform,
            menus: ["shareAppMessage"]
          });
        }
      } catch (error) {
        return createResult(false, {
          reason: "share_menu_init_failed",
          message: String(error && error.message ? error.message : error)
        });
      }

      return createResult(false, {
        reason: "share_menu_not_supported",
        message: "当前平台不支持 showShareMenu"
      });
    },

    callSync: function (methodNameJson, payloadJson) {
      const methodName = parseJson(methodNameJson);
      const payload = parseJson(payloadJson);

      try {
        switch (methodName) {
          case "getRuntimeInfo":
            return safeStringify(this.getRuntimeInfo());
          case "initShareMenu":
            return safeStringify(this.ensureShareMenu());
          case "saveGame":
            return safeStringify(this.saveGame(payload));
          case "loadGame":
            return safeStringify(this.loadGame());
          default:
            return safeStringify(createResult(false, {
              reason: "sync_method_not_found",
              message: "未找到同步方法: " + methodName
            }));
        }
      } catch (error) {
        return safeStringify(createResult(false, {
          reason: "sync_method_exception",
          message: String(error && error.message ? error.message : error),
          method: methodName
        }));
      }
    },

    startAsync: function (methodNameJson, payloadJson) {
      const methodName = parseJson(methodNameJson);
      const payload = parseJson(payloadJson);
      const requestId = "req_" + String(this.requestSeed++);
      this.pendingResults[requestId] = null;

      Promise.resolve()
        .then(() => this.runAsync(methodName, payload))
        .then((result) => {
          this.pendingResults[requestId] = result;
        })
        .catch((error) => {
          this.pendingResults[requestId] = createResult(false, {
            reason: "async_method_exception",
            message: String(error && error.message ? error.message : error),
            method: methodName
          });
        });

      return requestId;
    },

    consumeResult: function (requestIdJson) {
      const requestId = parseJson(requestIdJson);
      if (!Object.prototype.hasOwnProperty.call(this.pendingResults, requestId)) {
        return "";
      }
      const result = this.pendingResults[requestId];
      if (result === null) {
        return "";
      }
      delete this.pendingResults[requestId];
      return safeStringify(result);
    },

    runAsync: async function (methodName, payload) {
      switch (methodName) {
        case "requestLogin":
          return await this.requestLogin(payload);
        case "openShare":
          return await this.openShare(payload);
        case "showRewardedAd":
          return await this.showRewardedAd(payload);
        default:
          return createResult(false, {
            reason: "async_method_not_found",
            message: "未找到异步方法: " + methodName
          });
      }
    },

    getRuntimeInfo: function () {
      const api = this.getApi();
      const runtime = this.detectPlatform();
      const cfg = this.getPlatformConfig();
      let systemInfo = {};
      try {
        if (api && typeof api.getSystemInfoSync === "function") {
          systemInfo = api.getSystemInfoSync() || {};
        }
      } catch (_error) {
        systemInfo = {};
      }

      return createResult(true, {
        platform: runtime,
        visible: !!this.state.visible,
        sdkVersion: systemInfo.SDKVersion || "",
        system: systemInfo.system || "",
        brand: systemInfo.brand || "",
        model: systemInfo.model || "",
        appId: cfg.app_id || "",
        adUnitConfigured: !!cfg.rewarded_ad_unit_id
      });
    },

    requestLogin: async function (payload) {
      const api = this.getApi();
      const runtime = this.detectPlatform();
      const cfg = this.getPlatformConfig();

      if (!api || typeof api.login !== "function") {
        return createResult(false, {
          reason: "login_api_missing",
          message: "当前平台没有登录 API",
          platform: runtime
        });
      }

      if (runtime === "douyin" && !this.state.visible) {
        return createResult(false, {
          reason: "app_in_background",
          message: "小游戏处于后台，先回到前台再调用登录",
          platform: runtime
        });
      }

      return await new Promise((resolve) => {
        try {
          const options = {
            success: (res) => {
              const result = createResult(true, {
                platform: runtime,
                errMsg: res && res.errMsg ? res.errMsg : "",
                code: res && res.code ? res.code : "",
                anonymousCode: res && res.anonymousCode ? res.anonymousCode : "",
                isLogin: !!(res && res.isLogin),
                needBackendExchange: true
              });
              resolve(result);
            },
            fail: (err) => {
              resolve(createResult(false, {
                platform: runtime,
                reason: "login_failed",
                message: err && err.errMsg ? err.errMsg : "login failed"
              }));
            }
          };

          if (runtime === "wechat" && cfg.login_timeout_ms) {
            options.timeout = cfg.login_timeout_ms;
          }
          if (runtime === "douyin") {
            options.force = !!cfg.login_force;
          }

          api.login(options);
        } catch (error) {
          resolve(createResult(false, {
            platform: runtime,
            reason: "login_exception",
            message: String(error && error.message ? error.message : error)
          }));
        }
      });
    },

    openShare: async function (payload) {
      const api = this.getApi();
      const runtime = this.detectPlatform();
      const cfg = this.getPlatformConfig();
      const sharePayload = payload || {};

      if (!api) {
        return createResult(false, {
          reason: "platform_api_missing",
          message: "未检测到小游戏平台 API",
          platform: runtime
        });
      }

      try {
        this.ensureShareMenu();
      } catch (_error) {
      }

      if (runtime === "wechat") {
        if (typeof api.shareAppMessage !== "function") {
          return createResult(false, {
            reason: "share_api_missing",
            message: "微信小游戏未检测到 wx.shareAppMessage",
            platform: runtime
          });
        }

        try {
          api.shareAppMessage({
            title: sharePayload.title || cfg.share_title || "狙击外星人升级版",
            imageUrl: sharePayload.imageUrl || cfg.share_image_url || "",
            imageUrlId: sharePayload.imageUrlId || "",
            query: sharePayload.query || cfg.share_query || "",
            channel: sharePayload.channel || "shareAppMessage"
          });
          return createResult(true, {
            platform: runtime,
            accepted: true,
            message: "已调起微信小游戏分享面板"
          });
        } catch (error) {
          return createResult(false, {
            platform: runtime,
            reason: "share_exception",
            message: String(error && error.message ? error.message : error)
          });
        }
      }

      if (runtime === "douyin") {
        if (typeof api.shareAppMessage !== "function") {
          return createResult(false, {
            reason: "share_api_missing",
            message: "抖音小游戏未检测到 tt.shareAppMessage",
            platform: runtime
          });
        }

        return await new Promise((resolve) => {
          try {
            api.shareAppMessage({
              title: sharePayload.title || cfg.share_title || "狙击外星人升级版",
              imageUrl: sharePayload.imageUrl || cfg.share_image_url || "",
              query: sharePayload.query || cfg.share_query || "",
              channel: sharePayload.channel || cfg.share_channel || "invite",
              templateId: sharePayload.templateId || cfg.share_template_id || "",
              success: function (res) {
                resolve(createResult(true, {
                  platform: runtime,
                  accepted: true,
                  response: res || {}
                }));
              },
              fail: function (err) {
                resolve(createResult(false, {
                  platform: runtime,
                  reason: "share_failed",
                  message: err && err.errMsg ? err.errMsg : "share failed"
                }));
              }
            });
          } catch (error) {
            resolve(createResult(false, {
              platform: runtime,
              reason: "share_exception",
              message: String(error && error.message ? error.message : error)
            }));
          }
        });
      }

      return createResult(false, {
        platform: runtime,
        reason: "share_not_supported",
        message: "当前运行环境不是小游戏平台"
      });
    },

    getRewardedAdInstance: function (runtime, adUnitId) {
      const api = this.getApi();
      if (!api || typeof api.createRewardedVideoAd !== "function") {
        return null;
      }

      const cacheKey = runtime + ":" + adUnitId;
      if (this.rewardedAds[cacheKey]) {
        return this.rewardedAds[cacheKey];
      }

      const initPayload = { adUnitId: adUnitId };
      if (runtime === "wechat") {
        initPayload.multiton = false;
      }
      if (runtime === "douyin") {
        initPayload.multiton = false;
      }

      const ad = api.createRewardedVideoAd(initPayload);
      this.rewardedAds[cacheKey] = ad;
      return ad;
    },

    showRewardedAd: async function (payload) {
      const runtime = this.detectPlatform();
      const cfg = this.getPlatformConfig();
      const adUnitId = cfg.rewarded_ad_unit_id || "";

      if (!adUnitId) {
        return createResult(false, {
          platform: runtime,
          reason: "ad_unit_missing",
          message: "未配置激励视频广告位 ID"
        });
      }

      const ad = this.getRewardedAdInstance(runtime, adUnitId);
      if (!ad) {
        return createResult(false, {
          platform: runtime,
          reason: "rewarded_ad_api_missing",
          message: "当前平台未检测到激励视频广告 API"
        });
      }

      return await new Promise((resolve) => {
        let settled = false;

        const cleanup = () => {
          if (typeof ad.offClose === "function") ad.offClose(onClose);
          if (typeof ad.offError === "function") ad.offError(onError);
        };

        const finish = (result) => {
          if (settled) return;
          settled = true;
          cleanup();
          resolve(result);
        };

        const onClose = (res) => {
          const finished = !!(res && res.isEnded);
          const rewardedByFallback = !!(res && typeof res.count === "number" && res.count > 0);
          finish(createResult(finished || rewardedByFallback, {
            platform: runtime,
            placement: payload && payload.placement ? payload.placement : "",
            completed: finished,
            rewardedByFallbackShare: rewardedByFallback,
            count: res && typeof res.count === "number" ? res.count : 0,
            message: finished || rewardedByFallback ? "广告完成，可下发奖励" : "广告未看完，不下发奖励"
          }));
        };

        const onError = (err) => {
          finish(createResult(false, {
            platform: runtime,
            reason: "rewarded_ad_error",
            message: err && err.errMsg ? err.errMsg : safeStringify(err)
          }));
        };

        if (typeof ad.onClose === "function") ad.onClose(onClose);
        if (typeof ad.onError === "function") ad.onError(onError);

        Promise.resolve(ad.show())
          .catch(() => {
            if (typeof ad.load === "function") {
              return ad.load().then(() => ad.show());
            }
            throw new Error("rewarded ad show failed and load is unavailable");
          })
          .catch((error) => {
            finish(createResult(false, {
              platform: runtime,
              reason: "rewarded_ad_show_failed",
              message: String(error && error.message ? error.message : error)
            }));
          });
      });
    },

    saveGame: function (payload) {
      const api = this.getApi();
      const runtime = this.detectPlatform();
      const key = this.config.storage_key || "sniper_alien_profile_v1";

      if (!api || typeof api.setStorageSync !== "function") {
        return createResult(false, {
          platform: runtime,
          reason: "set_storage_sync_missing",
          message: "当前平台未检测到 setStorageSync"
        });
      }

      try {
        api.setStorageSync(key, payload);
        return createResult(true, {
          platform: runtime,
          storageKey: key
        });
      } catch (error) {
        return createResult(false, {
          platform: runtime,
          reason: "save_game_failed",
          message: String(error && error.message ? error.message : error),
          storageKey: key
        });
      }
    },

    loadGame: function () {
      const api = this.getApi();
      const runtime = this.detectPlatform();
      const key = this.config.storage_key || "sniper_alien_profile_v1";

      if (!api || typeof api.getStorageSync !== "function") {
        return createResult(false, {
          platform: runtime,
          reason: "get_storage_sync_missing",
          message: "当前平台未检测到 getStorageSync"
        });
      }

      try {
        const payload = api.getStorageSync(key);
        return createResult(true, {
          platform: runtime,
          storageKey: key,
          payload: payload || {}
        });
      } catch (error) {
        return createResult(false, {
          platform: runtime,
          reason: "load_game_failed",
          message: String(error && error.message ? error.message : error),
          storageKey: key,
          payload: {}
        });
      }
    }
  };

  window.__godotMiniGameBridge = bridge;
  return "ready";
})();
"""


func is_available() -> bool:
    return OS.has_feature("web")


func ensure_initialized(config: Dictionary) -> bool:
    if not is_available():
        return false

    JavaScriptBridge.eval(BRIDGE_BOOTSTRAP, true)
    var config_json := JSON.stringify(config)
    JavaScriptBridge.eval("window.__godotMiniGameBridge.configure(%s);" % JSON.stringify(config_json), true)
    return true


func detect_platform() -> String:
    if not is_available():
        return "mock"

    var result = JavaScriptBridge.eval("window.__godotMiniGameBridge ? window.__godotMiniGameBridge.detectPlatform() : 'browser';", true)
    return str(result)


func call_sync(method_name: String, payload: Dictionary = {}) -> Dictionary:
    if not is_available():
        return {
            "ok": false,
            "reason": "bridge_unavailable",
            "message": "当前不是 Web/小游戏运行环境",
        }

    var script := "window.__godotMiniGameBridge.callSync(%s, %s);" % [
        JSON.stringify(JSON.stringify(method_name)),
        JSON.stringify(JSON.stringify(payload)),
    ]
    return _parse_result(JavaScriptBridge.eval(script, true))


func call_async(method_name: String, payload: Dictionary = {}, timeout_sec: float = REQUEST_TIMEOUT_SEC) -> Dictionary:
    if not is_available():
        return {
            "ok": false,
            "reason": "bridge_unavailable",
            "message": "当前不是 Web/小游戏运行环境",
        }

    var request_script := "window.__godotMiniGameBridge.startAsync(%s, %s);" % [
        JSON.stringify(JSON.stringify(method_name)),
        JSON.stringify(JSON.stringify(payload)),
    ]
    var request_id := str(JavaScriptBridge.eval(request_script, true))
    if request_id.is_empty():
        return {
            "ok": false,
            "reason": "request_id_empty",
            "message": "小游戏桥未返回有效请求 ID",
        }

    var started_at := Time.get_ticks_msec()
    while float(Time.get_ticks_msec() - started_at) / 1000.0 < timeout_sec:
        var consume_script := "window.__godotMiniGameBridge.consumeResult(%s);" % JSON.stringify(JSON.stringify(request_id))
        var raw_result = JavaScriptBridge.eval(consume_script, true)
        var text := str(raw_result)
        if not text.is_empty():
            return _parse_result(text)
        await Engine.get_main_loop().create_timer(0.12).timeout

    return {
        "ok": false,
        "reason": "bridge_timeout",
        "message": "小游戏桥调用超时：%s" % method_name,
    }


func _parse_result(raw_result: Variant) -> Dictionary:
    if raw_result is Dictionary:
        return raw_result

    var text := str(raw_result)
    if text.is_empty():
        return {}

    var parsed = JSON.parse_string(text)
    if parsed is Dictionary:
        return parsed

    return {
        "ok": false,
        "reason": "bridge_parse_failed",
        "message": text,
    }
