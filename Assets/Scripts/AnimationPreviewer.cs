using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using Unity.VisualScripting;

#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Animations;
using UnityEditor.SceneManagement;
#endif

using UnityEngine;
using Versee.Scripts.Utils;

[ExecuteInEditMode]
public class AnimationPreviewer : MonoBehaviour
{
    public Animator AnimatorComponent;
    
    [Range(0, 1)]
    public float EditModeFreezeAt = 0.5f;
    
    [ActionButton("Preview", "PreviewAnimationState")]
    public string[] PrewAnimationStates;

    public string[] PreviewInEditMode;

    public void PreviewAnimationState(string stateName)
    {
        Debug.Log($"Preview Animation State: {stateName}");
        AnimatorComponent.CrossFade(stateName, 1f);
    }


    
    public void EnterNextAnimationState()
    {
        int currentIndex = 0;
        AnimatorStateInfo stateInfo = AnimatorComponent.GetCurrentAnimatorStateInfo(0);
        int hash = stateInfo.shortNameHash;
        foreach(string stateName in PrewAnimationStates)
        {
            if (Animator.StringToHash(stateName) == hash)
            {
                break;
            }
            currentIndex++;
        }
        
        int nextIndex = currentIndex + 1;
        if (nextIndex >= PrewAnimationStates.Length)
        {
            nextIndex = 0;
        }
        AnimatorComponent.Play(PrewAnimationStates[nextIndex]);
    }

    public void AutoGetAllAnimationStates()
    {
        #if UNITY_EDITOR

        AnimatorController controller = AnimatorComponent.runtimeAnimatorController as AnimatorController;

        if (controller != null)
        {
            // Get all the layers in the animation controller
            AnimatorControllerLayer[] layers = controller.layers;

            // Create a list to hold the animation state names
            List<string> stateNames = new List<string>();

            foreach (AnimatorControllerLayer layer in layers)
            {
                // Get the state machine of the layer
                AnimatorStateMachine stateMachine = layer.stateMachine;

                // Get all the states in the state machine
                foreach (ChildAnimatorState state in stateMachine.states)
                {
                    // Add the name of the state to the list
                    stateNames.Add(state.state.name);
                }
            }

            // Convert the list to an array of strings
            PrewAnimationStates = stateNames.ToArray();
        }

        #endif
    }
    
    public void UpdateFreeze()
    {
        #if UNITY_EDITOR
        if(UnityEditor.EditorApplication.isPlaying) return;
        
        // execute only in edit mode

        for(int i=0; i<PreviewInEditMode.Length; i++)
        {
            if (PreviewInEditMode[i]=="") continue;
            AnimatorComponent.Play(PreviewInEditMode[i], layer:i, Math.Max(EditModeFreezeAt, 0.01f));
        }
        
        //if (AnimatorComponent.GetCurrentAnimatorStateInfo(0).IsUnityNull()) return;
        //if (PrewAnimationStates.Length <= 0) return;

        try
        {
            AnimatorComponent.Update(0.0001f);
        }
        catch { Debug.Log("Error"); }

        #endif
    }

    private void Update()
    {
        UpdateFreeze();
    }
}

#if UNITY_EDITOR
[CustomEditor(typeof(AnimationPreviewer))]
public class AnimatorInspector : Editor
{
    

    public override void OnInspectorGUI()
    {
        AnimationPreviewer previewer = (AnimationPreviewer)target;

        if (previewer.AnimatorComponent == null)
        {
            try
            {
                previewer.AnimatorComponent = previewer.GetComponentInChildren<Animator>();
                serializedObject.ApplyModifiedProperties();
                EditorUtility.SetDirty(previewer);
                EditorSceneManager.MarkSceneDirty(EditorSceneManager.GetActiveScene());
            } catch { }
            
        }

        DrawDefaultInspector();

        // Button
        if (GUILayout.Button("Auto-Fill Animation States"))
        {
            previewer.AutoGetAllAnimationStates();
            serializedObject.ApplyModifiedProperties();
            EditorUtility.SetDirty(previewer);
            EditorSceneManager.MarkSceneDirty(EditorSceneManager.GetActiveScene());
        }

    }
}
#endif
