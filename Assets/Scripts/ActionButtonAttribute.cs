using System.Reflection;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Versee.Scripts.Utils
{
    public class ActionButtonAttribute : PropertyAttribute
    {
        public string buttonText;

        public string methodName;

        public ActionButtonAttribute(string buttonText, string methodName)
        {
            this.buttonText = buttonText;
            this.methodName = methodName;
        }
    }

    #if UNITY_EDITOR
    [CustomPropertyDrawer(typeof(ActionButtonAttribute))]
    public class ActionButtonDrawer : PropertyDrawer
    {
        public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
        {
            EditorGUI.BeginProperty(position, label, property);

            float buttonWidth = 60f;
            float spacing = 5f;

            // Draw the string property
            Rect textFieldPosition = new Rect(position.x, position.y, position.width - buttonWidth - spacing, position.height);
            EditorGUI.PropertyField(textFieldPosition, property, GUIContent.none);
            ActionButtonAttribute actionButtonAttribute = attribute as ActionButtonAttribute;

            // Draw the button
            Rect buttonPosition = new Rect(position.x + position.width - buttonWidth, position.y, buttonWidth, position.height);
            if (GUI.Button(buttonPosition, actionButtonAttribute.buttonText))
            {
                MethodInfo method = property.serializedObject.targetObject.GetType().GetMethod(actionButtonAttribute.methodName);
                if (method != null)
                {
                    method.Invoke(property.serializedObject.targetObject, new object[] { property.stringValue });
                }
            }

            EditorGUI.EndProperty();
        }
    }
    #endif
}