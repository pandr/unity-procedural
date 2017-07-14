using UnityEngine;
using System.Collections;

public class DrawProceduralDemo00 : MonoBehaviour
{
    public Material instanceMaterialProc;
    public int instanceCount;

    // Mono stuff
    void Start() { }
    void Update() { Tick(); }
    void OnDisable() { DeInit(); }

    public void Tick()
    {
        // Resize or recreate buffer if needed. Not we use extras.Length which is high-water mark for extras
        // to avoid constant recreation.
        if (m_InstanceBuffer == null || instanceCount != m_QuadCount)
        {
            if (m_InstanceBuffer != null)
                m_InstanceBuffer.Release();

            m_QuadCount = instanceCount;
            m_InstanceBuffer = new ComputeBuffer(m_QuadCount, 16 + 16 + 16);
            m_DataBuffer = new InstanceData[m_QuadCount];

            instanceMaterialProc.SetBuffer("positionBuffer", m_InstanceBuffer);

            for (var i = 0; i < m_QuadCount; i++)
            {
                var v = Random.onUnitSphere;
                m_DataBuffer[i].position = new Vector4(v.x, v.y, v.z, 0) * 0.0f;
                var d = Random.onUnitSphere;
                m_DataBuffer[i].size = new Vector4(d.x, d.y, d.z, 1.0f);
                m_DataBuffer[i].color = Random.ColorHSV(0, 1.0f, 0.3f, 0.5f, 0.5f, 1.0f, 1.0f, 1.0f);
            }
        }

        m_InstanceBuffer.SetData(m_DataBuffer, 0, 0, instanceCount);
        transform.Rotate(Vector3.one, Time.deltaTime * 5.0f);
    }

    void OnRenderObject()
    {
        instanceMaterialProc.SetMatrix("worldMat", transform.localToWorldMatrix);
        instanceMaterialProc.SetVector("peelRange", new Vector4(-1.0f, 0.0f, 0, 0));
        instanceMaterialProc.SetPass(0);
        Graphics.DrawProcedural(MeshTopology.Triangles, instanceCount * 60, 1);
        instanceMaterialProc.SetVector("peelRange", new Vector4(0.0f, 0.8f, 0, 0));
        instanceMaterialProc.SetPass(0);
        Graphics.DrawProcedural(MeshTopology.Triangles, instanceCount * 60, 1);
        instanceMaterialProc.SetVector("peelRange", new Vector4(0.8f, 1.2f, 0, 0));
        instanceMaterialProc.SetPass(0);
        Graphics.DrawProcedural(MeshTopology.Triangles, instanceCount * 60, 1);
    }

    public void DeInit()
    {
        if (m_InstanceBuffer != null)
            m_InstanceBuffer.Release();
        m_InstanceBuffer = null;

        m_DataBuffer = null;
    }

    struct InstanceData
    {
        public Vector4 position; // if UV are zero, dont sample
        public Vector4 size; // zw unused
        public Vector4 color;
    }

    int m_QuadCount = -1;

    ComputeBuffer m_InstanceBuffer;
    InstanceData[] m_DataBuffer;

}
