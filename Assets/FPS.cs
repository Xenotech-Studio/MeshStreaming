using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class FPS : MonoBehaviour
{
    public TMP_Text Text;
    
    private List<float> historyDeltaTime = new List<float>();

    public int HistoryCount = 100;

    private void Update()
    {
        if (historyDeltaTime.Count >= HistoryCount)
        {
            historyDeltaTime.RemoveAt(0);
        }
        
        historyDeltaTime.Add(Time.deltaTime);
        
        float sum = 0;
        foreach (var deltaTime in historyDeltaTime)
        {
            sum += deltaTime;
        }

        float average = sum / historyDeltaTime.Count;

        Text.text = $"FPS: {1 / average:F0}";
    }
}
