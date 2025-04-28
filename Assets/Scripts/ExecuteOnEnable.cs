using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class ExecuteOnEnable : MonoBehaviour
{
    public UnityEvent ExeOnEnable;

    private void OnEnable()
    {
        ExeOnEnable?.Invoke();
    }
}
