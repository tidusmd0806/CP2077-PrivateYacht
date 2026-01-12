// Title: Private Yacht Sound System
// Author: tidusmd
// Version: 1.0.3
// CopyRight (C) 2025, tidusmd. All rights reserved.
module PrivateYacht
@if(ModuleExists("Audioware"))
import Audioware.*

@addField(PlayerPuppet)
let m_yacht_emitter_id: EntityID;
@addField(PlayerPuppet)
let m_yacht_tag_name: CName;

@if(ModuleExists("Audioware"))
public class SoundSystem extends ScriptableSystem {
    private func OnAttach() {
        GameInstance.GetCallbackSystem().RegisterCallback(n"Entity/AfterAttach", this, n"OnYachtSpawn")
        .AddTarget(EntityTarget.RecordID(t"Vehicle.sq028_yacht_private"));
        GameInstance.GetCallbackSystem().RegisterCallback(n"Session/Ready", this, n"CheckAlwaysActiveYacht")
        .AddTarget(EntityTarget.RecordID(t"Vehicle.sq028_yacht_private"));
    }

    private cb func OnYachtSpawn(event: ref<EntityLifecycleEvent>) {
        let game = this.GetGameInstance();
        let player = GetPlayer(game);
        player.m_yacht_tag_name = n"PrivateYacht";
        let target = event.GetEntity();
        if !IsDefined(target) { return; }
        player.m_yacht_emitter_id = target.GetEntityID();
        if !GameInstance.GetAudioSystemExt(game).IsRegisteredEmitter(player.m_yacht_emitter_id, player.m_yacht_tag_name) {
            GameInstance.GetAudioSystemExt(game).RegisterEmitter(player.m_yacht_emitter_id, player.m_yacht_tag_name);
        }
    }

    private cb func CheckAlwaysActiveYacht(event: ref<GameSessionEvent>) {
        let game = this.GetGameInstance();
        let player = GetPlayer(game);
        if Equals(player.m_yacht_tag_name, n"PrivateYacht") {
            GameInstance.GetDelaySystem(GetGameInstance()).DelayCallback(CustomCallback.Create(2, game), 3.0, false);
        }
    }
}

@if(ModuleExists("Audioware"))
@addMethod(PlayerPuppet)
private cb func OnYachtSoundEvent(event: ref<ActionEvent>) {
    let game = this.GetGame();
    let event_name : CName = event.eventAction;
    if !GameInstance.GetAudioSystemExt(game).IsRegisteredEmitter(this.m_yacht_emitter_id, this.m_yacht_tag_name) {return;}
    if Equals(event_name, n"private_yacht_start") {
        GameInstance.GetAudioSystemExt(game).PlayOnEmitter(n"private_yacht_start", this.m_yacht_emitter_id, this.m_yacht_tag_name, LinearTween.Immediate(0.5));
        GameInstance.GetDelaySystem(GetGameInstance()).DelayCallback(CustomCallback.Create(1, game), 10.0, false);
    } else if Equals(event_name, n"private_yacht_end") {
        GameInstance.GetAudioSystemExt(game).StopOnEmitter(n"private_yacht_move", this.m_yacht_emitter_id, this.m_yacht_tag_name, LinearTween.Immediate(2.0));
        GameInstance.GetAudioSystemExt(game).PlayOnEmitter(n"private_yacht_end", this.m_yacht_emitter_id, this.m_yacht_tag_name, LinearTween.Immediate(0.5));
    } else if Equals(event_name, n"private_yacht_cancel") {
        GameInstance.GetAudioSystemExt(game).StopOnEmitter(n"private_yacht_move", this.m_yacht_emitter_id, this.m_yacht_tag_name, LinearTween.Immediate(2.0));
        GameInstance.GetAudioSystemExt(game).StopOnEmitter(n"private_yacht_start", this.m_yacht_emitter_id, this.m_yacht_tag_name, LinearTween.Immediate(2.0));
        GameInstance.GetAudioSystemExt(game).StopOnEmitter(n"private_yacht_end", this.m_yacht_emitter_id, this.m_yacht_tag_name, LinearTween.Immediate(2.0));
    }
}

@if(ModuleExists("Audioware"))
public class CustomCallback extends DelayCallback {
    private let func_num: Int32;
    private let game: GameInstance;
    public func Call() {
        if this.func_num == 1 {
            let player = GetPlayer(this.game);
            GameInstance.GetAudioSystemExt(this.game).PlayOnEmitter(n"private_yacht_move", player.m_yacht_emitter_id, player.m_yacht_tag_name, LinearTween.Immediate(1.0));
        } else if this.func_num == 2 {
            let player = GetPlayer(this.game);
            if !GameInstance.GetAudioSystemExt(this.game).IsRegisteredEmitter(player.m_yacht_emitter_id, player.m_yacht_tag_name) {
                GameInstance.GetAudioSystemExt(this.game).RegisterEmitter(player.m_yacht_emitter_id, player.m_yacht_tag_name);
            }
            GameInstance.GetAudioSystemExt(this.game).PlayOnEmitter(n"private_yacht_move", player.m_yacht_emitter_id, player.m_yacht_tag_name, LinearTween.Immediate(0.5));
        }
    }
    public static func Create(input_num: Int32, game: GameInstance) -> ref<CustomCallback> {
        let self = new CustomCallback();
        self.game = game;
        self.func_num = input_num;
        return self;
    }
}