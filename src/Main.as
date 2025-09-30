// c 2025-09-28
// m 2025-09-30

const string  pluginColor = "\\$F0A";
const string  pluginIcon  = Icons::SnapchatGhost;
Meta::Plugin@ pluginMeta  = Meta::ExecutingPlugin();
const string  pluginTitle = pluginColor + pluginIcon + "\\$G " + pluginMeta.Name;

void Main() {
    startnew(NvgLoopAsync);
}

void Render() {
    if (false
        or !S_Enabled
        or (true
            and S_HideWithGame
            and !UI::IsGameUIVisible()
        )
        or (true
            and S_HideWithOP
            and !UI::IsOverlayShown()
        )
    ) {
        return;
    }

    if (UI::Begin(pluginTitle + "###main-" + pluginMeta.ID, S_Enabled, UI::WindowFlags::None)) {
        RenderWindow();
    }
    UI::End();
}

void RenderMenu() {
    if (UI::MenuItem(pluginTitle, "", S_Enabled)) {
        S_Enabled = !S_Enabled;
    }
}

void RenderWindow() {
    auto App = cast<CTrackMania>(GetApp());

    if (false
        or !S_Enabled
        or (true
            and S_HideWithGame
            and !UI::IsGameUIVisible()
        )
        or (true
            and S_HideWithOP
            and !UI::IsOverlayShown()
        )
        or App.RootMap is null
        or App.GameScene is null
        or cast<CSmArenaClient>(App.CurrentPlayground) is null
        or App.CurrentPlayground.GameTerminals.Length == 0
        or App.CurrentPlayground.GameTerminals[0] is null
        or App.CurrentPlayground.GameTerminals[0].ControlledPlayer is null
    ) {
        return;
    }

    auto localPlayer = cast<CSmPlayer>(App.CurrentPlayground.GameTerminals[0].ControlledPlayer);
    if (localPlayer is null) {
        return;
    }

    const uint localPlayerId = GetPlayerVisId(App.GameScene, localPlayer);

    const vec2 screenSize = vec2(Draw::GetWidth(), Draw::GetHeight());
    const vec2 screenCenter = vec2(screenSize.x, screenSize.y) * 0.5f;

    const float safeZone = 30.0f;
    const vec2 renderBounds = screenSize - safeZone;

    CSceneVehicleVis@[] allVis = VehicleState::GetAllVis(App.GameScene);
    for (uint i = 0; i < allVis.Length; i++) {
        CSceneVehicleVis@ vis = allVis[i];
        if (false
            or vis is null
            or localPlayerId == Dev::GetOffsetUint32(vis, 0x0)
            or (true
                and i > 0
                and vis.AsyncState.Position == allVis[i - 1].AsyncState.Position
            )
        ) {
            continue;
        }

        vec3 screenPos = Camera::ToScreen(vis.AsyncState.Position);
        if (screenPos.z > 0) {
            // continue;
            // screenPos *= -1.0f;
        }
        UI::Text("screenPos: " + tostring(screenPos));

        bool offScreen = false;
        if (false
            or screenPos.x < 0.0f
            or screenPos.x > screenSize.x
            or screenPos.y < 0.0f
            or screenPos.y > screenSize.y
        ) {
            offScreen = true;
            UI::SameLine();
            UI::Text("(off screen)");
        }
    }
}

// from Multidash
uint GetPlayerVisId(ISceneVis@ scene, CSmPlayer@ player) {
    if (false
        or scene is null
        or player is null
    ) {
        return 0x0FF00000;
    }

    auto vis = VehicleState::GetVis(scene, player);
    if (vis is null) {
        return 0x0FF00000;
    }

    return Dev::GetOffsetUint32(vis, 0x0);
}

void NvgLoopAsync() {
    auto App = cast<CTrackMania>(GetApp());

    while (true) {
        yield();

        if (false
            or !S_Enabled
            or (true
                and S_HideWithGame
                and !UI::IsGameUIVisible()
            )
            or (true
                and S_HideWithOP
                and !UI::IsOverlayShown()
            )
            or App.RootMap is null
            or App.GameScene is null
            or cast<CSmArenaClient>(App.CurrentPlayground) is null
            or App.CurrentPlayground.GameTerminals.Length == 0
            or App.CurrentPlayground.GameTerminals[0] is null
            or App.CurrentPlayground.GameTerminals[0].ControlledPlayer is null
        ) {
            continue;
        }

        auto localPlayer = cast<CSmPlayer>(App.CurrentPlayground.GameTerminals[0].ControlledPlayer);
        if (localPlayer is null) {
            continue;
        }

        const uint localPlayerId = GetPlayerVisId(App.GameScene, localPlayer);

        const vec2 screenSize = vec2(Draw::GetWidth(), Draw::GetHeight());
        const vec3 screenCenter = vec3(screenSize.x, screenSize.y, 0.0f) * 0.5f;

        const float safeZone = 30.0f;

        CSceneVehicleVis@[] allVis = VehicleState::GetAllVis(App.GameScene);
        for (uint i = 0; i < allVis.Length; i++) {
            CSceneVehicleVis@ vis = allVis[i];
            if (false
                or vis is null
                or localPlayerId == Dev::GetOffsetUint32(vis, 0x0)
            ) {
                continue;
            }

            vec3 screenPos = Camera::ToScreen(vis.AsyncState.Position);
            // if (screenPos.z > 0.0f) {
            //     continue;
            // }

            bool onScreen = true;
            if (false
                or screenPos.x < safeZone
                or screenPos.x > screenSize.x - safeZone
                or screenPos.y < safeZone
                or screenPos.y > screenSize.y - safeZone
                or screenPos.z > 0.0f
            ) {
                onScreen = false;
            }

            if (onScreen) {
                nvg::BeginPath();
                nvg::MoveTo(screenCenter.xy);
                nvg::LineTo(screenPos.xy);
                nvg::ClosePath();
                nvg::StrokeColor(vec4(1.0f));
                nvg::StrokeWidth(2.0f);
                nvg::Stroke();

            } else {  // https://www.youtube.com/watch?v=gAQpR1GN0Os
                const vec4 color = screenPos.z > 0.0f ? vec4(1.0f, 0.0f, 0.0f, 1.0f) : vec4(1.0f);
                if (screenPos.z > 0.0f) {
                    screenPos *= -1.0f;  // mirror
                }

                screenPos -= screenCenter;

                float angle = Math::Atan2(screenPos.y, screenPos.x);
                angle -= Math::ToRad(90.0f);

                float cos = Math::Cos(angle);
                float sin = -Math::Sin(angle);

                // screenPos = screenCenter + vec3(sin, cos, 0.0f) * 150.0f;

                float m = cos / sin;

                vec3 screenBounds = screenCenter - safeZone;

                if (cos > 0.0f) {
                    screenPos = vec3(screenBounds.y / m, screenBounds.y, 0.0f);
                } else {
                    screenPos = vec3(-screenBounds.y / m, -screenBounds.y, 0.0f);
                }

                if (screenPos.x > screenBounds.x) {
                    screenPos = vec3(screenBounds.x, screenBounds.x * m, 0.0f);
                } else if (screenPos.x < -screenBounds.x) {
                    screenPos = vec3(-screenBounds.x, -screenBounds.x * m, 0.0f);
                }

                screenPos += screenCenter;

                nvg::BeginPath();
                nvg::MoveTo(screenCenter.xy);
                nvg::LineTo(screenPos.xy);
                nvg::ClosePath();
                nvg::StrokeColor(color);
                nvg::StrokeWidth(2.0f);
                nvg::Stroke();
            }

            nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
            nvg::FillColor(vec4(1.0f));
            nvg::FontSize(30.0f);
            nvg::Text(screenPos.xy, Text::Format("%.1f", vis.AsyncState.WorldVel.Length() * 3.6f));
        }
    }
}
